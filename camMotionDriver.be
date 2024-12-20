import string
import json
import webserver
import mqtt

# this is to be loaded as a driver
class camdriver
    var motion
    var act_count
    var act_count_start
    var data_ini
    
    def init()
        log('WCM: '..'webcam init')
        self.data_ini = '{"val":0, "bri":0, "pix":0}'
        self.act_count_start = 5
        self.act_count = 0
        
        self.motion = {
            'state':0,
            'detect':0,
            'data':self.data_ini
        }

        self.start()
    end

    def stop()
        self.stopmotion()
    end

    def start()
        self.stop()
        self.startmotion()
    end

    def stopmotion()
        if self.motion['state']
            tasmota.cmd("wcsetmotiondetect 0"); # enable basic motion detection, operated at the period specified.
            tasmota.cmd("wcsetmotiondetect3 0"); # set the pixel difference threshold (0-255). pixels which differ more than this from the previous image are counted.
            tasmota.cmd("wcsetmotiondetect4 0"); # set the count of pixels which must be different in 10000 pixels to trigger a motion event.
            tasmota.cmd("wcsetmotiondetect6 0"); # turn on/off difference buffer
            
            log('WCM: '..'stopped motion ')
            self.motion['detect'] = 0
            self.motion['state'] = 0
        end
    end

    def startmotion()
        if self.motion['state']
            self.stopmotion()
        end

        if self.motion['state'] == 0
            tasmota.cmd("wcsetmotiondetect7 600"); # overall normalised picture difference to cause detection
            tasmota.cmd("wcsetmotiondetect6 1"); # turn on/off difference buffer
            tasmota.cmd("wcsetmotiondetect3 10"); # set the pixel difference threshold (0-255). pixels which differ more than this from the previous image are counted.
            tasmota.cmd("wcsetmotiondetect4 10"); # set the count of pixels which must be different in 10000 pixels to trigger a motion event.
            tasmota.cmd("wcsetmotiondetect 2000"); # enable basic motion detection, operated at the period specified.

            log('WCM: '..'started motion')
            self.motion['state'] = 1
        end
    end
    
    def publish_state(detect)
        if tasmota.wifi().find('ip') == nil return nil end #- exit if not connected -#
        
        tasmota.cmd('mtrupdate {"name":"vmotion", "occupancy":'..detect..'}')
        log('WCM: '..tasmota.read_sensors())
    end

    # callback from webcam driver in tas on motion or other event 
    def webcam(cmd, idx, payload, x)
        if !self.motion || !self.motion['state'] return nil end  #- exit if not initialized -#
        # called when motion is detected
        if cmd == 'motion'
            log('WCM: '..cmd..' '..payload)
            self.motion['data'] = payload
            if self.motion['detect'] == 0
                self.motion['detect'] = 1
                self.publish_state(self.motion['detect'])
            end
            self.act_count = self.act_count_start
        end
    end

    def every_second()
        if !self.motion || !self.motion['state'] return nil end  #- exit if not initialized -#
        
        if self.act_count == 0
            self.act_count = -1
            self.motion['detect'] = 0
            self.motion['data'] = self.data_ini
            self.publish_state(self.motion['detect'])
        elif self.act_count > 0
            self.act_count -= 1
        end
    end

    def web_sensor()
        if !self.motion || !self.motion['state']  return nil end  #- exit if not initialized -#
        # log('WCM: '..'web_sensor')
        var data = json.load(self.motion['data'])
        var msg = string.format(
            "{s}Motion bri{m}%d{e}"..
            "{s}Motion pix{m}%d{e}"..
            "{s}Motion val{m}%d{e}",
            data['bri'], data['pix'], data['val'] )
        tasmota.web_send_decimal(msg)
    end

    #- add sensor value to teleperiod or read_sensors() function -#
    def json_append()
        if !self.motion || !self.motion['state']  return nil end  #- exit if not initialized -#
        var msg = string.format(",\"CamMotion\":{\"Detect\":%i}", self.motion['detect'])
        tasmota.response_append(msg)
    end

end


# if this is second run, remove the existing driver.
if global.webcam
  log('WCM: '.."removing existing driver")
  tasmota.remove_driver(global.webcam)
  global.webcam = nil
else
  # do nothing - normal first run
  log('WCM: '.."first run, no driver to remove")
end

global.webcam = camdriver() 
tasmota.add_driver(global.webcam)
log('WCM: '.."driver added")

