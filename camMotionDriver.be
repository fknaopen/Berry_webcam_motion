import string
import webserver

# this is to be loaded as a driver
class camdriver
    var motion

    def init()
        print('WCM: '..'webcam init')
        self.motion = {
            'state':0
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
        var options = self.motion;
        if options['state']
            self.stopmotion()
        end

        if options['state'] == 0
            tasmota.cmd("wcsetmotiondetect7 1000"); # overall normalised picture difference to cause detection
            tasmota.cmd("wcsetmotiondetect6 1"); # turn on/off difference buffer
            tasmota.cmd("wcsetmotiondetect3 10"); # set the pixel difference threshold (0-255). pixels which differ more than this from the previous image are counted.
            tasmota.cmd("wcsetmotiondetect4 10"); # set the count of pixels which must be different in 10000 pixels to trigger a motion event.
            tasmota.cmd("wcsetmotiondetect 2000"); # enable basic motion detection, operated at the period specified.
            options['state'] = 1
            print('WCM: '..'started motion')
        end
    end

    # callback from webcam driver in tas on motion or other event 
    def webcam(cmd, idx, payload, x)
        # called when motion is detected
        if cmd == 'motion'
            print('WCM: '..cmd..payload)
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

    def getlink(url, newpage, text)
        var js = "window.open('" .. url .."'"
        if newpage
            js  = js .. ",'_blank'" 
        else
            js  = js .. ",'_self'" 
        end
        js = js .. ")"

        return '<p></p><button onclick="' .. js .. '">' .. text .. '</button>'
    end

    def web_add_main_button()
        var url = '/timelapse/index.html'
        var newpage = 1
        var text = 'Timelapse Viewer'

        webserver.content_send(self.getlink(url, newpage, text))    
        webserver.content_send("<p></p><button onclick='la(\"&m_bewebcam=1\");'>Start/Restart Berry Webcam</button>")
        webserver.content_send("<p></p><button onclick='la(\"&m_bewebcam=2\");'>Stop Berry Webcam</button>")
    end

    def web_sensor()
        print('WCM: '..'web_sensor')
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

