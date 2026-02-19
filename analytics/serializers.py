from rest_framework import serializers
from .models import WorkoutLog

class WorkoutLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = WorkoutLog
        fields = ['id', 'user', 'duration_minutes', 'calories_burned', 'workout_type', 'date']