import string
import json
import webserver

# this is to be loaded as a driver
class camdriver
    var motion

    def init()
        print('WCM: '..'webcam init')
        self.motion = {
            'state':0,
            'val':0,
            'bri':0,
            'pix':0
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

    # turn off any features we may have turned on
    # and stop the motion detection
    def stopmotion()
        if self.motion['state']
            tasmota.cmd("wcsetmotiondetect 0"); # enable basic motion detection, operated at the period specified.
            tasmota.cmd("wcsetmotiondetect3 0"); # set the pixel difference threshold (0-255). pixels which differ more than this from the previous image are counted.
            tasmota.cmd("wcsetmotiondetect4 0"); # set the count of pixels which must be different in 10000 pixels to trigger a motion event.
            tasmota.cmd("wcsetmotiondetect6 0"); # turn on/off difference buffer
            
            print('WCM: '..'stopped motion ')
            self.motion['state'] = 0
        end
    end

    def startmotion()
        if self.motion['state']
            self.stopmotion()
        end

        if self.motion['state'] == 0
            tasmota.cmd("wcsetmotiondetect7 1000"); # overall normalised picture difference to cause detection
            tasmota.cmd("wcsetmotiondetect6 1"); # turn on/off difference buffer
            tasmota.cmd("wcsetmotiondetect3 10"); # set the pixel difference threshold (0-255). pixels which differ more than this from the previous image are counted.
            tasmota.cmd("wcsetmotiondetect4 10"); # set the count of pixels which must be different in 10000 pixels to trigger a motion event.
            tasmota.cmd("wcsetmotiondetect 2000"); # enable basic motion detection, operated at the period specified.
            self.motion['state'] = 1
            print('WCM: '..'started motion')
        end
    end

    # callback from webcam driver in tas on motion or other event 
    def webcam(cmd, idx, payload, x)
        # called when motion is detected
        if cmd == 'motion'
            print('WCM: '..cmd..' '..payload)
            var data = json.load(payload)
            self.motion['bri'] = data['bri']
            self.motion['pix'] = data['pix']
            self.motion['val'] = data['val']
        end

        # called when framesize changed by more than the configured amount.
        if cmd == 'framesizechange'
            print('WCM: '..cmd..payload)
        end

        # called every frame if enabled
        if cmd == "frame"
            print('WCM: '..'frame'..payload)
        end
    end

    def testmotion()
        self.webcam('motion', 0, '{"val":1000,"bri":15000,"pix":20}', {"val":1000,"bri":15000,"pix":20})
    end

    def web_sensor()
        # print('WCM: '..'web_sensor')
        var msg = string.format(
            "{s}Motion bri{m}%d{e}"..
            "{s}Motion pix{m}%d{e}"..
            "{s}Motion val{m}%d{e}",
            self.motion['bri'], self.motion['pix'], self.motion['val'] )
        tasmota.web_send_decimal(msg)
        
        if webserver.has_arg("m_bewebcam")
            var val = webserver.arg("m_bewebcam");
            print('WCM: '..'m_bewebcam'..val)
            if val == '1'
                self.start()
            else
                self.stop()
            end
        end
    end

end


# if this is second run, remove the existing driver.
if global.webcam
  print('WCM: '.."removing existing driver")
  tasmota.remove_driver(global.webcam)
  global.webcam = nil
else
  # do nothing - normal first run
  print('WCM: '.."first run, no driver to remove")
end

global.webcam = camdriver() 
tasmota.add_driver(global.webcam)
print('WCM: '.."driver added")

