package com.eventplatform.event.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "event_capacity")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EventCapacity {

    @Id
    @Column(name = "event_id")
    private Long eventId;

    @Column(name = "total_capacity", nullable = false)
    private Integer totalCapacity;

    @Column(name = "reserved_capacity", nullable = false)
    @Builder.Default
    private Integer reservedCapacity = 0;

    @Column(name = "available_capacity")
    private Integer availableCapacity;

    // Helper method to check if capacity is available
    public boolean hasAvailableCapacity(int requestedQuantity) {
        return availableCapacity >= requestedQuantity;
    }

    // Helper method to reserve capacity
    public boolean reserveCapacity(int quantity) {
        if (hasAvailableCapacity(quantity)) {
            this.reservedCapacity += quantity;
            this.availableCapacity -= quantity;
            return true;
        }
        return false;
    }

    // Helper method to release capacity
    public void releaseCapacity(int quantity) {
        this.reservedCapacity = Math.max(0, this.reservedCapacity - quantity);
        this.availableCapacity = this.totalCapacity - this.reservedCapacity;
    }
}





