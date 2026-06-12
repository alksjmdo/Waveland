import QtQuick

QtObject {
    id: eventBus
    property var _subscribers: ({})

    function subscribe(eventName, callback){
        if(!_subscribers[eventName]) 
            _subscribers[eventName] = []
        _subscribers[eventName].push(callback)
        
    }

    function publish(eventName, data){
        var subs = _subscribers[eventName]
        if (subs){
            for(var i = 0; i<subs.length; i++){
                subs[i](data)
            }
        }
    }

    function unsubscribe(eventName, callback){
        var subs = _subscribers[eventName]
        if (subs) {
            var idx = subs.indexOf(callback)
            if (idx >= 0) subs.splice(idx,1)
        }
    }

}