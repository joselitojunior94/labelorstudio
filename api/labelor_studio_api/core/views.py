from django.shortcuts import render

from django.contrib.auth.models import User
from rest_framework.decorators import api_view, permission_classes, action
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from django.db import transaction
from .models import Dataset, DatasetItem, DatasetColumn, Evaluation, Judgment, Review
from rest_framework import viewsets, status
from .serializers import DatasetSerializer, DatasetItemSerializer, EvaluationSerializer
from django.db import models as djm
from openai import OpenAI
import csv, io, json, os


import csv, io, json

def _normalize_header(raw_header):
    header = [(str(h).strip() if str(h).strip()!='' else None) for h in raw_header]
    return [h if h else f'col_{i}' for i,h in enumerate(header)]

def _normalize_row(row, H):
    row=[str(x) for x in row]
    if len(row)>H: row=row[:H]
    elif len(row)<H: row=row+['']*(H-len(row))
    return row
    
@api_view(['POST'])
@permission_classes([AllowAny])
def register(request):
    username = request.data.get('username')
    password = request.data.get('password')

    if not username or not password:
        return Response({'detail':'username and password required'}, status=400)
    
    if User.objects.filter(username=username).exists():
        return Response({'detail':'username already exists'}, status=400)
    
    u = User.objects.create_user(username=username, password=password)

    return Response({'id': u.id, 'username': u.username}, status=201)

class UploadCsvView(APIView):
    permission_classes=[IsAuthenticated]

    def post(self, request, dataset_id=None):
        f = request.FILES.get('file')
        meta_raw = request.POST.get('meta')

        if not f or not meta_raw:
            return Response({'detail':'file and meta are required'}, status=400)
        
        try: 
            meta = json.loads(meta_raw)
        except: 
            return Response({'detail':'invalid meta json'}, status=400)
        
        delimiter = meta.get('delimiter', ','); encoding = meta.get('encoding','UTF-8')

        blob = f.read(); f.seek(0)

        with transaction.atomic():
            if dataset_id:
                ds = get_object_or_404(Dataset, pk=dataset_id)
                ds.version += 1
                ds.original_file.save(f"{ds.id}_v{ds.version}.csv", f)
                ds.delimiter = delimiter; ds.encoding = encoding; ds.save()
                ds.items.all().delete()

            else:
                dataset_name = meta.get('dataset_name') or f.name
                ds = Dataset.objects.create(name=dataset_name, created_by=request.user, delimiter=delimiter, encoding=encoding)
                ds.original_file.save(f"{ds.id}_v1.csv", f); ds.save()

            try: 
                text = blob.decode('utf-8') if encoding.upper()=='UTF-8' else blob.decode('latin1')

            except: text = blob.decode('utf-8', errors='ignore')

            reader = csv.reader(io.StringIO(text), delimiter=('\t' if delimiter=='\t' else delimiter))

            rows = list(reader)

            if not rows: return Response({'detail':'empty csv'}, status=400)

            header = _normalize_header(rows[0])     

            H = len(header)
            
            items=[DatasetItem(dataset=ds, row_index=i, data=dict(zip(header, _normalize_row(r,H))))
                   for i,r in enumerate(rows[1:])]
            if items: DatasetItem.objects.bulk_create(items, batch_size=1000)

        return Response({'dataset_id': ds.id, 'version': ds.version})

class DatasetViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Dataset.objects.all().select_related('created_by')
    serializer_class = DatasetSerializer

    @action(detail=True, methods=['get'])
    def items(self, request, pk=None):
        ds = self.get_object()
        qs = ds.items.all().order_by('row_index')
        page=int(request.query_params.get('page',1)); page_size=int(request.query_params.get('page_size',50))
        s=(page-1)*page_size; e=s+page_size
        ser=DatasetItemSerializer(qs[s:e], many=True)
        return Response({'count': qs.count(), 'page': page, 'results': ser.data})

@api_view(['POST'])
def save_mapping(request, dataset_id, version):
    ds = get_object_or_404(Dataset, pk=dataset_id)
    cols = request.data.get('columns', [])
    ds.columns.all().delete()
    to_create = [DatasetColumn(dataset=ds,
                 name_in_file=c.get('name_in_file') or c.get('mapped_name'),
                 mapped_name=c.get('mapped_name') or c.get('name_in_file'),
                 role=c.get('role','FEATURE'),
                 dtype=c.get('dtype','string'),
                 required=bool(c.get('required', False))) for c in cols]
    if to_create: DatasetColumn.objects.bulk_create(to_create, batch_size=500)
    return Response({'ok': True, 'count': len(to_create)})

class EvaluationViewSet(viewsets.ModelViewSet):
    serializer_class = EvaluationSerializer

    def get_queryset(self):
        u=self.request.user
        return (Evaluation.objects
                .filter(djm.Q(owner=u)|djm.Q(judges=u)|djm.Q(reviewers=u)|djm.Q(viewers=u))
                .distinct().select_related('dataset','owner'))

class EvaluationItemsView(APIView):
    permission_classes=[IsAuthenticated]
    def get(self, request, eval_id):
        ev=get_object_or_404(Evaluation, pk=eval_id)
  
        ds=ev.dataset; qs=ds.items.all().order_by('row_index')
        page=int(request.query_params.get('page',1)); page_size=int(request.query_params.get('page_size',50))
        s=(page-1)*page_size; e=s+page_size
        ser=DatasetItemSerializer(qs[s:e], many=True)
        return Response({'count': qs.count(), 'page': page, 'results': ser.data})

class JudgmentCreateView(APIView):
    permission_classes=[IsAuthenticated]
    def post(self, request, eval_id, item_id):
        ev=get_object_or_404(Evaluation, pk=eval_id)
        if ev.status=='closed': return Response({'detail':'evaluation closed'}, status=400)
    
        item=get_object_or_404(DatasetItem, pk=item_id, dataset=ev.dataset)
        val=request.data.get('value'); conf=request.data.get('confidence')
        Judgment.objects.update_or_create(evaluation=ev, item=item, judge=request.user, defaults={'value': val, 'confidence': conf})
        return Response({'ok': True})

class ReviewCreateView(APIView):
    permission_classes=[IsAuthenticated]
    def post(self, request, eval_id, item_id):
        ev=get_object_or_404(Evaluation, pk=eval_id)
        if ev.status=='closed': return Response({'detail':'evaluation closed'}, status=400)

        item=get_object_or_404(DatasetItem, pk=item_id, dataset=ev.dataset)
        notes=request.data.get('notes',''); acc=request.data.get('accepted_value','')
        Review.objects.update_or_create(evaluation=ev, item=item, reviewer=request.user, defaults={'notes':notes,'accepted_value':acc})
        return Response({'ok': True})

@api_view(['GET'])
def evaluation_metrics(request, eval_id):
    ev = get_object_or_404(Evaluation, pk=eval_id)
    judgs = Judgment.objects.filter(evaluation=ev)
    by_item={}
    for j in judgs:
        by_item.setdefault(j.item_id, {})[j.judge_id]=j.value
    judges=sorted({j.judge_id for j in judgs})
    items=[iid for iid,d in by_item.items() if len(d)>=2]

    import numpy as np
    def kappa(l1,l2):
        if not l1: return None
        cats=sorted(list(set(l1)|set(l2))); idx={c:i for i,c in enumerate(cats)}
        M=np.zeros((len(cats),len(cats)), dtype=int)
        for a,b in zip(l1,l2): M[idx[a], idx[b]]+=1
        total=M.sum(); po=(np.trace(M)/total) if total else 0.0
        pi=(M.sum(axis=0)/total) @ (M.sum(axis=1)/total) if total else 0.0
        if pi==1.0: return 1.0
        return (po-pi)/(1-pi) if (1-pi)!=0 else 0.0

    pairs=[]
    for i in range(len(judges)):
        for j in range(i+1,len(judges)):
            a,b=judges[i],judges[j]; l1=[]; l2=[]
            for iid in items:
                d=by_item[iid]
                if a in d and b in d: l1.append(d[a]); l2.append(d[b])
            pairs.append({'judges':[a,b],'cohen_kappa': kappa(l1,l2) if l1 else None})
    return Response({'judge_ids': judges, 'pairs': pairs, 'items_used': len(items)})

@api_view(['GET'])
def evaluation_results(request, eval_id):
    ev=get_object_or_404(Evaluation, pk=eval_id)
    judgs=Judgment.objects.filter(evaluation=ev)
    by_item={}
    for j in judgs: by_item.setdefault(j.item_id, []).append(j.value)
    out=[]
    from collections import Counter
    for iid, labels in by_item.items():
        c=Counter(labels); majority=c.most_common(1)[0][0]
        out.append({'item_id': iid, 'majority': majority, 'counts': dict(c)})
    return Response({'results': out})

from django.http import HttpResponse
@api_view(['GET'])
def export_results_csv(request, eval_id):
    ev=get_object_or_404(Evaluation, pk=eval_id)
    judgs=Judgment.objects.filter(evaluation=ev)
    rows=[['item_id','judge_id','label','confidence']]
    for j in judgs: rows.append([j.item_id, j.judge_id, j.value, j.confidence if j.confidence is not None else ''])
    out=io.StringIO(); csv.writer(out).writerows(rows)
    resp=HttpResponse(out.getvalue(), content_type='text/csv')
    resp['Content-Disposition'] = f'attachment; filename="evaluation_{ev.id}_judgments.csv"'
    return resp

@api_view(['GET'])
def export_results_json(request, eval_id):
    ev=get_object_or_404(Evaluation, pk=eval_id)
    judgs=Judgment.objects.filter(evaluation=ev)
    data=[{'item_id': j.item_id, 'judge_id': j.judge_id, 'label': j.value, 'confidence': j.confidence} for j in judgs]
    return Response({'evaluation': ev.id, 'judgments': data})

@api_view(['POST'])
def close_evaluation(request, eval_id):
    ev=get_object_or_404(Evaluation, pk=eval_id)
    if ev.owner_id != request.user.id:
        return Response({'detail':'only owner can close'}, status=403)
    ev.status='closed'; ev.save(update_fields=['status'])
    return Response({'ok': True, 'status': ev.status})


client = OpenAI(api_key="<<ADD KEY>>")
MODEL = os.getenv("OPENAI_MODEL", "gpt-4o-mini")

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def ai_suggest(request):
    
    title = (request.data.get("title") or "").strip()
    body  = (request.data.get("body") or "").strip()
    if not title and not body:
        return Response({"error": "Informe title ou body"}, status=400)

    try:
        prompt = f"""
        You are a labeling wizard.
        Analyze the following item (title + description) and suggest a short label and a rationale. 
        Respond **in JSON only** in the format:
        {{"label": "...", "reason": "..."}}

        Title: {title}
        Description: {body}
        """

        resp = client.chat.completions.create(
            model=MODEL,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.2,
        )

        content = resp.choices[0].message.content.strip()

        
        try:
            parsed = json.loads(content)
        except Exception:
            parsed = {"label": None, "reason": content[:300]}

        out = {
            "label": parsed.get("label"),
            "reason": parsed.get("reason"),
            "_model": MODEL,
        }
        return Response(out, status=200)

    except Exception as e:
        return Response({"error": str(e)}, status=500)