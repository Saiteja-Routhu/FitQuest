from django.core.management.base import BaseCommand
from nutrition.models import FoodItem


class Command(BaseCommand):
    help = "Seed global food items (coach=None, is_global=True)"

    def handle(self, *args, **kwargs):
        foods = [
            # Proteins
            {"name": "Chicken Breast", "calories": 165, "protein": 31, "carbs": 0, "fats": 3.6, "serving_unit": "100g"},
            {"name": "Eggs", "calories": 155, "protein": 13, "carbs": 1.1, "fats": 11, "serving_unit": "100g", "measurement_type": "per_unit", "unit_name": "egg"},
            {"name": "Whey Protein", "calories": 120, "protein": 25, "carbs": 3, "fats": 1.5, "serving_unit": "30g", "measurement_type": "per_unit", "unit_name": "scoop"},
            {"name": "Canned Tuna", "calories": 116, "protein": 26, "carbs": 0, "fats": 1, "serving_unit": "100g"},
            {"name": "Salmon", "calories": 208, "protein": 20, "carbs": 0, "fats": 13, "serving_unit": "100g"},
            {"name": "Lean Beef", "calories": 250, "protein": 26, "carbs": 0, "fats": 15, "serving_unit": "100g"},
            {"name": "Cottage Cheese", "calories": 98, "protein": 11, "carbs": 3.4, "fats": 4.3, "serving_unit": "100g"},
            {"name": "Greek Yogurt", "calories": 59, "protein": 10, "carbs": 3.6, "fats": 0.4, "serving_unit": "100g"},
            {"name": "Tofu", "calories": 76, "protein": 8, "carbs": 1.9, "fats": 4.8, "serving_unit": "100g"},
            {"name": "Red Lentils", "calories": 116, "protein": 9, "carbs": 20, "fats": 0.4, "serving_unit": "100g"},
            {"name": "Paneer", "calories": 265, "protein": 18, "carbs": 3.6, "fats": 20, "serving_unit": "100g"},
            # Carbs
            {"name": "Rolled Oats", "calories": 389, "protein": 17, "carbs": 66, "fats": 7, "serving_unit": "100g"},
            {"name": "White Rice", "calories": 130, "protein": 2.7, "carbs": 28, "fats": 0.3, "serving_unit": "100g"},
            {"name": "Brown Rice", "calories": 123, "protein": 2.6, "carbs": 26, "fats": 0.9, "serving_unit": "100g"},
            {"name": "Sweet Potato", "calories": 86, "protein": 1.6, "carbs": 20, "fats": 0.1, "serving_unit": "100g"},
            {"name": "Banana", "calories": 89, "protein": 1.1, "carbs": 23, "fats": 0.3, "serving_unit": "100g", "measurement_type": "per_unit", "unit_name": "banana"},
            {"name": "Whole Wheat Bread", "calories": 247, "protein": 13, "carbs": 41, "fats": 4.2, "serving_unit": "100g"},
            {"name": "Pasta", "calories": 371, "protein": 13, "carbs": 74, "fats": 1.1, "serving_unit": "100g"},
            {"name": "Quinoa", "calories": 120, "protein": 4.4, "carbs": 21, "fats": 1.9, "serving_unit": "100g"},
            {"name": "White Potato", "calories": 77, "protein": 2, "carbs": 17, "fats": 0.1, "serving_unit": "100g"},
            # Fats
            {"name": "Almonds", "calories": 579, "protein": 21, "carbs": 22, "fats": 50, "serving_unit": "100g"},
            {"name": "Peanut Butter", "calories": 588, "protein": 25, "carbs": 20, "fats": 50, "serving_unit": "100g"},
            {"name": "Avocado", "calories": 160, "protein": 2, "carbs": 9, "fats": 15, "serving_unit": "100g"},
            {"name": "Olive Oil", "calories": 884, "protein": 0, "carbs": 0, "fats": 100, "serving_unit": "100ml"},
            {"name": "Walnuts", "calories": 654, "protein": 15, "carbs": 14, "fats": 65, "serving_unit": "100g"},
            {"name": "Cashews", "calories": 553, "protein": 18, "carbs": 30, "fats": 44, "serving_unit": "100g"},
            # Vegetables
            {"name": "Broccoli", "calories": 34, "protein": 2.8, "carbs": 7, "fats": 0.4, "serving_unit": "100g"},
            {"name": "Spinach", "calories": 23, "protein": 2.9, "carbs": 3.6, "fats": 0.4, "serving_unit": "100g"},
            {"name": "Cucumber", "calories": 15, "protein": 0.7, "carbs": 3.6, "fats": 0.1, "serving_unit": "100g"},
            {"name": "Carrots", "calories": 41, "protein": 0.9, "carbs": 10, "fats": 0.2, "serving_unit": "100g"},
            {"name": "Tomato", "calories": 18, "protein": 0.9, "carbs": 3.9, "fats": 0.2, "serving_unit": "100g"},
            # Dairy
            {"name": "Full Fat Milk", "calories": 61, "protein": 3.2, "carbs": 4.8, "fats": 3.3, "serving_unit": "100ml"},
            {"name": "Skim Milk", "calories": 35, "protein": 3.4, "carbs": 5, "fats": 0.1, "serving_unit": "100ml"},
            {"name": "Cheddar Cheese", "calories": 402, "protein": 25, "carbs": 1.3, "fats": 33, "serving_unit": "100g"},
            {"name": "Butter", "calories": 717, "protein": 0.9, "carbs": 0.1, "fats": 81, "serving_unit": "100g"},
        ]

        created = 0
        for food in foods:
            obj, was_created = FoodItem.objects.get_or_create(
                name=food["name"],
                is_global=True,
                defaults={
                    "coach": None,
                    "calories": food["calories"],
                    "protein": food["protein"],
                    "carbs": food["carbs"],
                    "fats": food["fats"],
                    "serving_unit": food.get("serving_unit", "100g"),
                    "measurement_type": food.get("measurement_type", "per_100g"),
                    "unit_name": food.get("unit_name", "unit"),
                    "is_global": True,
                }
            )
            if was_created:
                created += 1

        self.stdout.write(self.style.SUCCESS(f"Seeded {created} new global foods ({len(foods)} total checked)"))
