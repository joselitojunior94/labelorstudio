from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Dataset, DatasetColumn, DatasetItem, Evaluation

class UserMiniSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "username", "email"]

class DatasetColumnSerializer(serializers.ModelSerializer):

    class Meta: 
        model = DatasetColumn 

        fields = '__all__'

class DatasetSerializer(serializers.ModelSerializer):
    columns = DatasetColumnSerializer(many=True, read_only=True)

    class Meta: 
        model = Dataset

        fields = ['id','name','created_by','created_at','delimiter','encoding','version','original_file','columns']

class DatasetItemSerializer(serializers.ModelSerializer):

    class Meta: 
        model = DatasetItem

        fields = ['id','row_index','data']

class EvaluationSerializer(serializers.ModelSerializer):
    owner = UserMiniSerializer(read_only=True)
    judges = serializers.PrimaryKeyRelatedField(many=True, queryset=User.objects.all(), required=False)
    reviewers = serializers.PrimaryKeyRelatedField(many=True, queryset=User.objects.all(), required=False)
    viewers = serializers.PrimaryKeyRelatedField(many=True, queryset=User.objects.all(), required=False)
    
    class Meta: 
        model=Evaluation

        fields='__all__'

    def create(self, vd):
        judges=vd.pop('judges',[])
        reviewers=vd.pop('reviewers',[])
        viewers=vd.pop('viewers',[])
        
        req=self.context['request']
        
        ev=Evaluation.objects.create(owner=req.user, **vd)
        
        ev.judges.set(list(set([*judges, req.user])))
        
        ev.reviewers.set(reviewers)
        
        ev.viewers.set(viewers)

        return ev