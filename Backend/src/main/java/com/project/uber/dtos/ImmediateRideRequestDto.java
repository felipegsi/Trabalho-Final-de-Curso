package com.project.uber.dtos;

import com.project.uber.enums.Category;

public record ImmediateRideRequestDto(
        String origin,
        String destination,
        Category category,
        int width,
        int height,
        int length,
        int weight
) {

}
