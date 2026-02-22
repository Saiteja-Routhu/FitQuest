from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('nutrition', '0004_dietschedule'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.AddField(
            model_name='fooditem',
            name='measurement_type',
            field=models.CharField(
                choices=[('per_100g', 'Per 100g'), ('per_unit', 'Per Unit')],
                default='per_100g',
                max_length=10,
            ),
        ),
        migrations.AddField(
            model_name='fooditem',
            name='unit_name',
            field=models.CharField(
                default='unit',
                help_text="e.g. 'egg', 'slice', 'scoop'. Used when measurement_type=per_unit",
                max_length=20,
            ),
        ),
        migrations.CreateModel(
            name='Recipe',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=100)),
                ('instructions', models.TextField(blank=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('coach', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='recipes', to=settings.AUTH_USER_MODEL)),
            ],
        ),
        migrations.CreateModel(
            name='RecipeIngredient',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('quantity', models.FloatField(default=1.0)),
                ('food_item', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='nutrition.fooditem')),
                ('recipe', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='ingredients', to='nutrition.recipe')),
            ],
        ),
    ]
