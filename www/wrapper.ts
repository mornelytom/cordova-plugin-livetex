import { Injectable } from '@angular/core';
import { Plugin, IonicNativePlugin, Cordova } from '@ionic-native/core';

@Plugin({
    pluginName: 'Livetex', // should match the name of the wrapper class
    plugin: 'cordova-plugin-livetex', // NPM package name
    pluginRef: 'cordova.plugins.livetex', // name of the object exposed by the plugin
    platforms: ['Android'] // supported platforms
})

@Injectable()
export class Livetex extends IonicNativePlugin {

    @Cordova()
    init(): Promise<any> { return; }

    @Cordova()
    open(): Promise<any> { return; }
}