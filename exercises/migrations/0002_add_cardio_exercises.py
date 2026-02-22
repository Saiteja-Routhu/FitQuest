from django.db import migrations


def add_cardio(apps, schema_editor):
    Exercise = apps.get_model('workouts', 'Exercise')
    cardio_exercises = [
        ('Running', 'Steady-state outdoor or treadmill running', 'Cardio', 'Beginner', 'None'),
        ('Jump Rope', 'Skipping rope for cardiovascular conditioning', 'Cardio', 'Beginner', 'Jump Rope'),
        ('Rowing Machine', 'Full-body cardio on the rowing ergometer', 'Cardio', 'Intermediate', 'Machine'),
        ('Cycling (Stationary)', 'Low-impact cycling for endurance', 'Cardio', 'Beginner', 'Machine'),
        ('Stair Climber', 'Step-mill machine for lower body cardio', 'Cardio', 'Intermediate', 'Machine'),
        ('Burpees', 'Full-body explosive cardio movement', 'Cardio', 'Intermediate', 'None'),
        ('Mountain Climbers', 'Core and cardio bodyweight exercise', 'Cardio', 'Beginner', 'None'),
        ('High Knees', 'Running in place with high knee drive', 'Cardio', 'Beginner', 'None'),
        ('Box Jumps', 'Explosive plyometric jump onto a box', 'Cardio', 'Intermediate', 'Plyo Box'),
        ('Battle Ropes', 'Upper body and cardio conditioning with ropes', 'Cardio', 'Intermediate', 'Battle Ropes'),
        ('Assault Bike', 'Full-body air bike for HIIT intervals', 'Cardio', 'Intermediate', 'Machine'),
        ('Sprint Intervals', 'Short all-out sprints with rest periods', 'Cardio', 'Intermediate', 'None'),
        ('Swimming', 'Full-body low-impact cardio in water', 'Cardio', 'Beginner', 'None'),
        ('Elliptical', 'Low-impact gliding motion cardio machine', 'Cardio', 'Beginner', 'Machine'),
    ]
    for name, desc, group, diff, equip in cardio_exercises:
        Exercise.objects.get_or_create(
            name=name,
            defaults={
                'description': desc,
                'muscle_group': group,
                'difficulty': diff,
                'equipment_needed': equip,
            }
        )


def remove_cardio(apps, schema_editor):
    Exercise = apps.get_model('workouts', 'Exercise')
    names = [
        'Running', 'Jump Rope', 'Rowing Machine', 'Cycling (Stationary)',
        'Stair Climber', 'Burpees', 'Mountain Climbers', 'High Knees',
        'Box Jumps', 'Battle Ropes', 'Assault Bike', 'Sprint Intervals',
        'Swimming', 'Elliptical',
    ]
    Exercise.objects.filter(name__in=names).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('exercises', '0001_initial'),
        ('workouts', '0002_exercise_rename_plan_name_workoutplan_name_and_more'),
    ]

    operations = [
        migrations.RunPython(add_cardio, remove_cardio),
    ]
