package com.gdmec.campchannel.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration
@EnableWebSocket
public class RawWebSocketConfig implements WebSocketConfigurer {

    private final RawWebSocketHandler rawWebSocketHandler;

    public RawWebSocketConfig(RawWebSocketHandler rawWebSocketHandler) {
        this.rawWebSocketHandler = rawWebSocketHandler;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(rawWebSocketHandler, "/ws/raw")
                .setAllowedOriginPatterns("*");
    }
}
