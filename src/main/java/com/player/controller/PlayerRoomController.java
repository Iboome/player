package com.player.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

/**
 * Created by ronger on 2017/5/12.
 */
@Controller
public class PlayerRoomController {

    @RequestMapping("/")
    public String index(){
        return "index";
    }

    @RequestMapping("/index")
    public String indexs(){
        return "index";
    }

}
