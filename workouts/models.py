from django.db import models
from users.models import CustomUser


class Exercise(models.Model):
    DIFFICULTY_CHOICES = [('Beginner', 'Beginner'), ('Intermediate', 'Intermediate'), ('Advanced', 'Advanced')]

    # ✅ UPDATED MUSCLE GROUPS (Separated Biceps & Triceps)
    MUSCLE_GROUPS = [
        ('Chest', 'Chest'),
        ('Back', 'Back'),
        ('Legs', 'Legs'),
        ('Shoulders', 'Shoulders'),
        ('Biceps', 'Biceps'),  # 👈 New
        ('Triceps', 'Triceps'),  # 👈 New
        ('Core', 'Core'),
        ('Cardio', 'Cardio'),
        ('Full Body', 'Full Body')
    ]

    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    muscle_group = models.CharField(max_length=50, choices=MUSCLE_GROUPS)
    difficulty = models.CharField(max_length=20, choices=DIFFICULTY_CHOICES, default='Beginner')
    video_url = models.URLField(blank=True, null=True)
    equipment_needed = models.CharField(max_length=100, default="None")

    def __str__(self):
        return self.name


class WorkoutPlan(models.Model):
    coach = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='created_plans')
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    assigned_to = models.ManyToManyField(CustomUser, related_name='assigned_plans', blank=True)

    def __str__(self):
        return f"{self.name} (by {self.coach.username})"


class WorkoutExercise(models.Model):
    plan = models.ForeignKey(WorkoutPlan, on_delete=models.CASCADE, related_name='workout_exercises')
    exercise = models.ForeignKey(Exercise, on_delete=models.CASCADE)
    sets = models.IntegerField(default=3)
    reps = models.CharField(max_length=20, default="10-12")
    rest_time = models.IntegerField(help_text="Seconds", default=60)
    order = models.IntegerField(default=1)

    class Meta:
        ordering = ['order']

    def __str__(self):
        return f"{self.exercise.name} in {self.plan.name}"