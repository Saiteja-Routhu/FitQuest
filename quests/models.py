from datetime import date
from django.db import models
from users.models import CustomUser


class Quest(models.Model):
    DIFFICULTY_CHOICES = [
        ('EASY',   'Easy'),
        ('MEDIUM', 'Medium'),
        ('HARD',   'Hard'),
    ]

    coach       = models.ForeignKey(
        CustomUser, on_delete=models.CASCADE, related_name='created_quests',
        limit_choices_to={'role': 'GUILD_MASTER'}
    )
    title       = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    xp_reward   = models.IntegerField(default=0)
    coin_reward = models.IntegerField(default=0)
    difficulty  = models.CharField(
        max_length=10, choices=DIFFICULTY_CHOICES, default='MEDIUM')
    assigned_to = models.ManyToManyField(
        CustomUser, related_name='assigned_quests', blank=True,
        limit_choices_to={'role': 'RECRUIT'}
    )
    is_community = models.BooleanField(default=False)
    is_auto_generated = models.BooleanField(default=False)
    created_at  = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'{self.title} (by {self.coach.username})'


class QuestCompletion(models.Model):
    recruit      = models.ForeignKey(
        CustomUser, on_delete=models.CASCADE, related_name='completed_quests')
    quest        = models.ForeignKey(
        Quest, on_delete=models.CASCADE, related_name='completions')
    completed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('recruit', 'quest')

    def __str__(self):
        return f'{self.recruit.username} completed {self.quest.title}'


class DailyQuestCompletion(models.Model):
    user = models.ForeignKey(
        CustomUser, on_delete=models.CASCADE, related_name='daily_quest_completions')
    source_type = models.CharField(max_length=20)  # 'workout' or 'nutrition'
    source_id = models.IntegerField()
    date = models.DateField(default=date.today)

    class Meta:
        unique_together = ('user', 'source_type', 'source_id', 'date')

    def __str__(self):
        return f'{self.user.username} — {self.source_type}:{self.source_id} on {self.date}'


class Guild(models.Model):
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    members = models.ManyToManyField(CustomUser, related_name='guilds', blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name


class CoOpQuest(models.Model):
    METRIC_CHOICES = [
        ('steps', 'Total Steps'),
        ('weight', 'Total Weight Lifted (kg)'),
    ]
    guild = models.ForeignKey(Guild, on_delete=models.CASCADE, related_name='active_quests')
    title = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    target_metric = models.CharField(max_length=20, choices=METRIC_CHOICES)
    target_value = models.IntegerField()
    current_progress = models.IntegerField(default=0)
    deadline = models.DateTimeField()
    is_completed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'{self.title} for {self.guild.name}'
