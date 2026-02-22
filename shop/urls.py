from django.urls import path
from . import views

urlpatterns = [
    # Coach shop (existing)
    path('',                             views.CoachShopView.as_view(),         name='coach-shop'),
    path('create/',                      views.CreateShopItemView.as_view(),     name='create-shop-item'),
    path('<int:pk>/',                    views.ShopItemDetailView.as_view(),     name='shop-item-detail'),
    path('purchases/',                   views.CoachPurchasesView.as_view(),     name='coach-purchases'),
    path('purchases/<int:pk>/fulfill/',  views.FulfillPurchaseView.as_view(),   name='fulfill-purchase'),
    path('available/',                   views.AvailableShopView.as_view(),     name='available-shop'),
    path('purchase/',                    views.PurchaseItemView.as_view(),       name='purchase-item'),
    path('my-purchases/',                views.MyPurchasesView.as_view(),        name='my-purchases'),

    # Super Coach services
    path('services/',                          views.SCServiceListView.as_view(),         name='sc-services'),
    path('services/create/',                   views.SCServiceCreateView.as_view(),       name='sc-service-create'),
    path('services/<int:pk>/',                 views.SCServiceDetailView.as_view(),       name='sc-service-detail'),
    path('services/purchase/',                 views.SCServicePurchaseView.as_view(),     name='sc-service-purchase'),
    path('services/purchases/',                views.SCServicePurchasesView.as_view(),    name='sc-service-purchases'),
    path('services/purchases/<int:pk>/fulfill/', views.SCFulfillPurchaseView.as_view(),  name='sc-fulfill-purchase'),
    path('services/my-purchases/',             views.MyServicePurchasesView.as_view(),   name='sc-my-purchases'),
]
