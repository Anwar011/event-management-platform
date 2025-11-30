package com.eventplatform.gateway.filter;

import com.eventplatform.common.util.CorrelationIdUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.util.UUID;

@Slf4j
@Component
public class CorrelationIdFilter implements GlobalFilter, Ordered {

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        ServerHttpRequest request = exchange.getRequest();
        String correlationId = request.getHeaders().getFirst(CorrelationIdUtil.CORRELATION_ID_HEADER);

        if (correlationId == null || correlationId.isEmpty()) {
            correlationId = UUID.randomUUID().toString();
        }

        ServerHttpRequest modifiedRequest = request.mutate()
                .header(CorrelationIdUtil.CORRELATION_ID_HEADER, correlationId)
                .build();

        ServerHttpResponse response = exchange.getResponse();
        response.getHeaders().add(CorrelationIdUtil.CORRELATION_ID_HEADER, correlationId);

        return chain.filter(exchange.mutate().request(modifiedRequest).build());
    }

    @Override
    public int getOrder() {
        return -200;
    }
}

