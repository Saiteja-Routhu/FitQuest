from rest_framework import serializers
from .models import Exercise, WorkoutPlan, WorkoutExercise
from users.serializers import UserSerializer


class ExerciseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Exercise
        fields = '__all__'


class WorkoutExerciseSerializer(serializers.ModelSerializer):
    exercise = ExerciseSerializer(read_only=True)
    exercise_id = serializers.PrimaryKeyRelatedField(
        queryset=Exercise.objects.all(), source='exercise', write_only=True
    )

    class Meta:
        model = WorkoutExercise
        fields = ['id', 'exercise', 'exercise_id', 'sets', 'reps', 'rest_time', 'order', 'day_label']


class WorkoutPlanSerializer(serializers.ModelSerializer):
    workout_exercises = WorkoutExerciseSerializer(many=True)  # Matches related_name in model
    coach = serializers.StringRelatedField(read_only=True)
    assigned_count = serializers.SerializerMethodField()

    def get_assigned_count(self, obj):
        return obj.assigned_to.count()

    class Meta:
        model = WorkoutPlan
        fields = ['id', 'name', 'description', 'day_names', 'coach', 'workout_exercises',
                  'assigned_count', 'created_at']

    def create(self, validated_data):
        exercises_data = validated_data.pop('workout_exercises')
        plan = WorkoutPlan.objects.create(**validated_data)

        for ex_data in exercises_data:
            WorkoutExercise.objects.create(plan=plan, **ex_data)

        return plan