from rest_framework import serializers
from .models import PoseAnalysis, RecoveryScore, StrengthPrediction, VoiceCommand

class PoseAnalysisSerializer(serializers.ModelSerializer):
    class Meta:
        model = PoseAnalysis
        fields = '__all__'

class RecoveryScoreSerializer(serializers.ModelSerializer):
    class Meta:
        model = RecoveryScore
        fields = '__all__'