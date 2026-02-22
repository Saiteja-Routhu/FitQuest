from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('workouts', '0003_workoutexercise_day_label'),
    ]

    operations = [
        migrations.AddField(
            model_name='workoutplan',
            name='day_names',
            field=models.JSONField(blank=True, default=dict),
        ),
    ]
