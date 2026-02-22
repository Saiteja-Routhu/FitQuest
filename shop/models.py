from django.db import models
from users.models import CustomUser


class ShopItem(models.Model):
    coach       = models.ForeignKey(
        CustomUser, on_delete=models.CASCADE, related_name='shop_items',
        limit_choices_to={'role': 'GUILD_MASTER'}
    )
    name        = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    coin_price  = models.IntegerField(default=0)
    is_active   = models.BooleanField(default=True)
    created_at  = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'{self.name} ({self.coin_price} coins)'


class Purchase(models.Model):
    recruit      = models.ForeignKey(
        CustomUser, on_delete=models.CASCADE, related_name='purchases')
    item         = models.ForeignKey(
        ShopItem, on_delete=models.CASCADE, related_name='purchases')
    purchased_at = models.DateTimeField(auto_now_add=True)
    is_fulfilled = models.BooleanField(default=False)

    def __str__(self):
        return f'{self.recruit.username} bought {self.item.name}'


class SuperCoachService(models.Model):
    super_coach = models.ForeignKey(
        CustomUser, on_delete=models.CASCADE,
        limit_choices_to={'role': 'SUPER_COACH'},
        related_name='sc_services'
    )
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    coin_price = models.IntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'{self.name} by {self.super_coach.username}'


class ServicePurchase(models.Model):
    recruit = models.ForeignKey(
        CustomUser, on_delete=models.CASCADE, related_name='service_purchases')
    service = models.ForeignKey(
        SuperCoachService, on_delete=models.CASCADE, related_name='purchases')
    purchased_at = models.DateTimeField(auto_now_add=True)
    is_fulfilled = models.BooleanField(default=False)

    def __str__(self):
        return f'{self.recruit.username} bought {self.service.name}'
