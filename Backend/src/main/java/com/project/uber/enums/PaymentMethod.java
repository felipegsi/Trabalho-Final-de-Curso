package com.project.uber.enums;
import lombok.Getter;
@Getter
public enum PaymentMethod {
    CASH("Cash"),
    CREDIT_CARD("Credit Card"),
    DEBIT_CARD("Debit Card"),
    PAYPAL("PayPal"),
    BANK_TRANSFER("Bank Transfer");

    private final String displayValue;
    PaymentMethod(String displayValue) {
        this.displayValue = displayValue;
    }

}
