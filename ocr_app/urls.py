from django.urls import path
from .views import photo_card_view, passport_view, driver_license_view, root_view

urlpatterns = [
    path('', root_view, name='root'),
    path('photo-cards/', photo_card_view, name='photo_cards'),
    path('passports/', passport_view, name='passports'),
    path('driver-licenses/', driver_license_view, name='driver_licenses'),
]
