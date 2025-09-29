from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
from django.core.validators import MinValueValidator

class Dataset(models.Model):
    name = models.CharField(max_length=200)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='datasets')
    created_at = models.DateTimeField(default=timezone.now)
    original_file = models.FileField(upload_to='datasets/')
    delimiter = models.CharField(max_length=4, default=',')
    encoding = models.CharField(max_length=32, default='UTF-8')
    version = models.IntegerField(default=1)

class DatasetColumn(models.Model):
    ROLE_CHOICES = [('ID','ID'),('TEXT','TEXT'),('FEATURE','FEATURE'),('LABEL','LABEL'),('IGNORE','IGNORE')]

    dataset = models.ForeignKey(Dataset, on_delete=models.CASCADE, related_name='columns')
    name_in_file = models.CharField(max_length=200)
    mapped_name = models.CharField(max_length=200)
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default='FEATURE')
    dtype = models.CharField(max_length=20, default='string')
    required = models.BooleanField(default=False)

class DatasetItem(models.Model):
    dataset = models.ForeignKey(Dataset, on_delete=models.CASCADE, related_name='items')
    row_index = models.IntegerField(validators=[MinValueValidator(0)])
    data = models.JSONField()

    class Meta: unique_together = ('dataset','row_index')

class Evaluation(models.Model):
    name = models.CharField(max_length=200)
    dataset = models.ForeignKey(Dataset, on_delete=models.CASCADE, related_name='evaluations')
    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name='owned_evaluations')
    judges = models.ManyToManyField(User, related_name='judge_evaluations', blank=True)
    reviewers = models.ManyToManyField(User, related_name='review_evaluations', blank=True)
    viewers = models.ManyToManyField(User, related_name='view_evaluations', blank=True)
    status = models.CharField(max_length=20, default='draft') 
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    metrics = models.JSONField(default=dict, blank=True)

class Judgment(models.Model):
    evaluation = models.ForeignKey(Evaluation, on_delete=models.CASCADE, related_name='judgments')
    item = models.ForeignKey(DatasetItem, on_delete=models.CASCADE, related_name='judgments')
    judge = models.ForeignKey(User, on_delete=models.CASCADE, related_name='judgments')
    value = models.CharField(max_length=200)
    confidence = models.FloatField(null=True, blank=True)
    created_at = models.DateTimeField(default=timezone.now)
    class Meta: unique_together = ('evaluation','item','judge')

class Review(models.Model):
    evaluation = models.ForeignKey(Evaluation, on_delete=models.CASCADE, related_name='reviews')
    item = models.ForeignKey(DatasetItem, on_delete=models.CASCADE, related_name='reviews')
    reviewer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reviews')
    notes = models.TextField(blank=True)
    accepted_value = models.CharField(max_length=200, blank=True)
    created_at = models.DateTimeField(default=timezone.now)
    class Meta: unique_together = ('evaluation','item','reviewer')
