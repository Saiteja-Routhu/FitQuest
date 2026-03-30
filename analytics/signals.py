from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import WorkoutSetLog
from ai_services.models import AICoachMessage
from workouts.models import WorkoutExercise, WorkoutPlan
from django.utils import timezone
import datetime

@receiver(post_save, sender=WorkoutSetLog)
def check_for_ai_coaching_intervention(sender, instance, created, **kwargs):
    if not created:
        return
    
    user = instance.user
    # Get last 3 sets for this user
    recent_logs = WorkoutSetLog.objects.filter(user=user).order_by('-logged_at')[:3]
    
    if recent_logs.count() < 3:
        return
    
    all_too_hard = all(log.effectiveness == 'Too Hard' for log in recent_logs)
    
    if all_too_hard:
        # Check if we already sent a recovery message today
        today_start = timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
        already_sent = AICoachMessage.objects.filter(
            user=user, 
            intervention_type='recovery', 
            created_at__gte=today_start
        ).exists()
        
        if not already_sent:
            AICoachMessage.objects.create(
                user=user,
                message="Agentic AI Notice: You've rated your last few workouts as 'Too Hard'. I have proactively adjusted tomorrow's plan to focus on recovery.",
                intervention_type='recovery'
            )
            
            # PROACTIVE ADJUSTMENT: Reduce sets by 1 for tomorrow's exercises
            tomorrow = (datetime.date.today() + datetime.timedelta(days=1)).strftime('%A')
            
            # Find plans assigned to this user
            assigned_plans = user.assigned_plans.all()
            
            # Find exercises for tomorrow in those plans
            tomorrow_exercises = WorkoutExercise.objects.filter(
                plan__in=assigned_plans,
                day_label=tomorrow
            )
            
            for we in tomorrow_exercises:
                if we.sets > 1:
                    we.sets -= 1
                    we.save()
