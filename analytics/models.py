from datetime import date
from django.db import models
from django.conf import settings
from django.utils import timezone


class WorkoutLog(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    duration_minutes = models.IntegerField()
    calories_burned = models.FloatField()
    workout_type = models.CharField(max_length=100)
    date = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.workout_type} ({self.date.date()})"


class DailyActivity(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='daily_activities'
    )
    date = models.DateField(default=date.today)
    water_ml = models.IntegerField(default=0)
    water_goal_ml = models.IntegerField(default=2500)
    steps = models.IntegerField(default=0)
    step_goal = models.IntegerField(default=8000)

    class Meta:
        unique_together = ('user', 'date')

    def __str__(self):
        return f"{self.user.username} — {self.date}"


class BodyProgressEntry(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='body_progress'
    )
    date = models.DateField(default=date.today)
    weight_kg = models.FloatField(null=True, blank=True)
    waist_cm = models.FloatField(null=True, blank=True)
    chest_cm = models.FloatField(null=True, blank=True)
    arms_cm = models.FloatField(null=True, blank=True)
    thighs_cm = models.FloatField(null=True, blank=True)
    photo_front_b64 = models.TextField(blank=True)
    photo_side_b64 = models.TextField(blank=True)
    photo_back_b64 = models.TextField(blank=True)
    photo_front = models.ImageField(upload_to='body_scans/', null=True, blank=True)
    photo_side = models.ImageField(upload_to='body_scans/', null=True, blank=True)
    photo_back = models.ImageField(upload_to='body_scans/', null=True, blank=True)
    ai_analysis = models.TextField(blank=True)
    body_fat_estimate = models.FloatField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} — {self.date}"


class UserActivityStatus(models.Model):
    ACTIVITY_CHOICES = [
        ('idle', 'Idle'),
        ('walking', 'Walking'),
        ('working_out', 'Working Out'),
    ]
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='activity_status'
    )
    last_heartbeat = models.DateTimeField(null=True, blank=True)
    activity_type = models.CharField(
        max_length=20, choices=ACTIVITY_CHOICES, default='idle')
    steps_live = models.IntegerField(default=0)

    def __str__(self):
        return f"{self.user.username} — {self.activity_type}"


class WorkoutSetLog(models.Model):
    EFFECTIVENESS_CHOICES = [
        ('Too Easy', 'Too Easy'),
        ('Just Right', 'Just Right'),
        ('Very Hard', 'Very Hard'),
    ]
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='set_logs'
    )
    exercise_name = models.CharField(max_length=100)
    workout_plan_name = models.CharField(max_length=100, blank=True)
    date = models.DateField(default=date.today)
    set_number = models.IntegerField(default=1)
    reps = models.IntegerField()
    weight_kg = models.FloatField(null=True, blank=True)
    effectiveness = models.CharField(max_length=20, choices=EFFECTIVENESS_CHOICES)
    logged_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} — {self.exercise_name} set {self.set_number}"