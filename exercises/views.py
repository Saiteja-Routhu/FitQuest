from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from .models import Exercise
from .serializers import ExerciseSerializer

@api_view(['GET'])
@permission_classes([AllowAny]) # Allow anyone to see exercises (even before login)
def get_all_exercises(request):
    """
    Get all exercises or filter them.
    Usage: /api/exercises/?muscle=chest&difficulty=beginner
    """
    exercises = Exercise.objects.all()

    # Filtering Logic
    muscle = request.query_params.get('muscle')
    difficulty = request.query_params.get('difficulty')
    equipment = request.query_params.get('equipment')

    if muscle:
        exercises = exercises.filter(muscle_group=muscle)
    if difficulty:
        exercises = exercises.filter(difficulty=difficulty)
    if equipment:
        exercises = exercises.filter(equipment=equipment)

    serializer = ExerciseSerializer(exercises, many=True)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_exercise_detail(request, exercise_id):
    """Get a single exercise by ID"""
    try:
        exercise = Exercise.objects.get(id=exercise_id)
        serializer = ExerciseSerializer(exercise)
        return Response(serializer.data)
    except Exercise.DoesNotExist:
        return Response({'error': 'Exercise not found'}, status=404)