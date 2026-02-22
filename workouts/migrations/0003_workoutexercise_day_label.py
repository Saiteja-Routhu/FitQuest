from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('workouts', '0002_exercise_rename_plan_name_workoutplan_name_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='workoutexercise',
            name='day_label',
            field=models.CharField(
                choices=[
                    ('Monday', 'Monday'), ('Tuesday', 'Tuesday'),
                    ('Wednesday', 'Wednesday'), ('Thursday', 'Thursday'),
                    ('Friday', 'Friday'), ('Saturday', 'Saturday'),
                    ('Sunday', 'Sunday'), ('Any', 'Any'),
                ],
                default='Any',
                max_length=10,
            ),
        ),
    ]
