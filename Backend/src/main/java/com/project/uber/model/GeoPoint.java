package com.project.uber.model;

public class GeoPoint {
    String pickupLocation;

    public GeoPoint(String pickupLocation) {
        this.pickupLocation = pickupLocation;
    }

    public GeoPoint() {
    }

    public String getPickupLocation() {
        return pickupLocation;
    }

    public void setPickupLocation(String pickupLocation) {
        this.pickupLocation = pickupLocation;
    }

}
