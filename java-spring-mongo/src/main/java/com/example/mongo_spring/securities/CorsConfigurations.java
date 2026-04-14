package com.example.mongo_spring.securities;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
@EnableWebMvc
public class CorsConfigurations implements WebMvcConfigurer {
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOrigins(new String[]{"http://localhost:5173", "http://localhost:5174", "http://localhost:3000", "http://localhost:8081", "http://localhost:4200", "http://localhost:3001", "http://127.0.0.1:5173/", "http://127.0.0.1:5174/"}).allowedMethods(new String[]{"GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"}).allowedHeaders(new String[]{"*"}).allowCredentials(true);
    }
}
