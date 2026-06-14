package com.opensoundtouch.controller;

import com.opensoundtouch.service.RadioBrowserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/radio")
@CrossOrigin(origins = "*")
public class RadioController {

    @Autowired
    private RadioBrowserService radioBrowserService;

    @GetMapping("/search")
    public List<Map<String, Object>> search(
            @RequestParam(required = false) String name,
            @RequestParam(required = false) String country,
            @RequestParam(required = false) String language,
            @RequestParam(defaultValue = "25") int limit
    ) {
        int safeLimit = Math.min(Math.max(limit, 1), 100);
        return radioBrowserService.searchStations(name, country, language, safeLimit);
    }
}
