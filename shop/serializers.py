from rest_framework import serializers
from .models import ShopItem, Purchase


class ShopItemSerializer(serializers.ModelSerializer):
    purchase_count = serializers.SerializerMethodField()

    class Meta:
        model  = ShopItem
        fields = [
            'id', 'name', 'description', 'coin_price',
            'is_active', 'created_at', 'purchase_count',
        ]
        read_only_fields = ['coach', 'created_at']

    def get_purchase_count(self, obj):
        return obj.purchases.count()


class PurchaseSerializer(serializers.ModelSerializer):
    item_name      = serializers.CharField(source='item.name',       read_only=True)
    recruit_name   = serializers.CharField(source='recruit.username', read_only=True)
    coin_price     = serializers.IntegerField(source='item.coin_price', read_only=True)

    class Meta:
        model  = Purchase
        fields = [
            'id', 'item', 'item_name', 'recruit_name',
            'coin_price', 'purchased_at', 'is_fulfilled',
        ]
