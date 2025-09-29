from django.urls import path, include
from rest_framework import routers
from . import views
from .views import UploadCsvView, DatasetViewSet, save_mapping, EvaluationViewSet, JudgmentCreateView, ReviewCreateView, EvaluationItemsView, evaluation_metrics, evaluation_results, export_results_csv, export_results_json, close_evaluation

router = routers.DefaultRouter()
router.register(r'datasets', DatasetViewSet, basename='dataset')
router.register(r'evaluations', EvaluationViewSet, basename='evaluation')

urlpatterns = [
  path('auth/register/', views.register),
  path('datasets/upload-csv/', UploadCsvView.as_view()),
  path('datasets/<int:dataset_id>/upload-csv/', UploadCsvView.as_view()),
  path('datasets/<int:dataset_id>/versions/<int:version>/mapping/', save_mapping),
  path('evaluations/<int:eval_id>/items/', EvaluationItemsView.as_view()),
  path('evaluations/<int:eval_id>/items/<int:item_id>/judgments/', JudgmentCreateView.as_view()),
  path('evaluations/<int:eval_id>/items/<int:item_id>/reviews/', ReviewCreateView.as_view()),
  path('evaluations/<int:eval_id>/metrics/', evaluation_metrics),
  path('evaluations/<int:eval_id>/results/', evaluation_results),
  path('evaluations/<int:eval_id>/export/csv/', export_results_csv),
  path('evaluations/<int:eval_id>/export/json/', export_results_json),
  path('evaluations/<int:eval_id>/close/', close_evaluation),

  path('', include(router.urls)),
]
