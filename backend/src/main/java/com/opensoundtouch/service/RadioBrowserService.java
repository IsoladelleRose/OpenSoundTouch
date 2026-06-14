package com.opensoundtouch.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URI;
import java.util.List;
import java.util.Map;

@Service
public class RadioBrowserService {

    private static final Logger logger = LoggerFactory.getLogger(RadioBrowserService.class);

    @Value("${radiobrowser.base-url:https://de1.api.radio-browser.info}")
    private String baseUrl;

    @Value("${radiobrowser.user-agent:OpenSoundTouch/0.1}")
    private String userAgent;

    private final RestTemplate restTemplate = new RestTemplate();

    public List<Map<String, Object>> searchStations(String name, String country, String language, int limit) {
        URI uri = UriComponentsBuilder.fromHttpUrl(baseUrl)
                .path("/json/stations/search")
                .queryParam("limit", limit)
                .queryParam("hidebroken", true)
                .queryParam("order", "clickcount")
                .queryParam("reverse", true)
                .queryParamIfPresent("name", name == null || name.isBlank() ? java.util.Optional.empty() : java.util.Optional.of(name))
                .queryParamIfPresent("country", country == null || country.isBlank() ? java.util.Optional.empty() : java.util.Optional.of(country))
                .queryParamIfPresent("language", language == null || language.isBlank() ? java.util.Optional.empty() : java.util.Optional.of(language))
                .build()
                .toUri();

        HttpHeaders headers = new HttpHeaders();
        headers.set("User-Agent", userAgent);
        HttpEntity<Void> request = new HttpEntity<>(headers);

        logger.info("Radio-Browser search: {}", uri);
        ResponseEntity<List<Map<String, Object>>> response = restTemplate.exchange(
                uri,
                HttpMethod.GET,
                request,
                new org.springframework.core.ParameterizedTypeReference<>() {
                }
        );
        return response.getBody() == null ? List.of() : response.getBody();
    }
}
