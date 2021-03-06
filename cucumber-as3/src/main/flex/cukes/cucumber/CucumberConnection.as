/**
 * User: miguel
 * Date: 18/09/2013
 */
package cukes.cucumber
{
import cukes.cucumber.events.CucumberRequestEvent;

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.ProgressEvent;
import flash.net.Socket;

[Event(name="request", type="cukes.cucumber.events.CucumberRequestEvent")]
[Event(name="connection_closed", type="cukes.cucumber.events.CucumberRequestEvent")]

public class CucumberConnection extends EventDispatcher implements ICucumberConnection
{

    public static var EOT:String = "\n";

    private var _socket : Socket;

    public function start(socket:Socket) : void
    {
        trace("cucumber socket created: " + socket.localAddress + ":" + socket.localPort);
        if(!_socket)
        {
            _socket = socket;
            _socket.addEventListener(Event.CONNECT, onSocketDataReceived);
            _socket.addEventListener(ProgressEvent.SOCKET_DATA, onSocketDataReceived);
            _socket.addEventListener(Event.CLOSE, onSocketClose);
        }
    }

    public function destroy():void
    {
        if( _socket != null )
        {
            _socket.removeEventListener(Event.CONNECT, onSocketDataReceived);
            _socket.removeEventListener(ProgressEvent.SOCKET_DATA, onSocketDataReceived);
            trace("closing socket, is connected=" + _socket.connected);
            if( _socket.connected )
            {
                _socket.close();
            }
            _socket = null;
        }
    }

    public function send(data:Array):void
    {
        const encoded:String = JSON.stringify(data);
        _socket.writeUTFBytes(encoded + EOT);
        _socket.flush();
    }

    private function onSocketDataReceived(event:Event):void
    {
        const rawSocketData : String = _socket.readUTFBytes(_socket.bytesAvailable);
        trace("cucumber socket request received: " + rawSocketData + " --END");
        if(rawSocketData != EOT)
        {
            const data : Array = JSON.parse(rawSocketData) as Array;
            dispatchRequestEvent(data);
        }
    }

    private function dispatchRequestEvent(data:Array) : void
    {
        const messageType : String = data[0];
        const payload : Object = data[1];
        const event : CucumberRequestEvent =
                new CucumberRequestEvent(CucumberRequestEvent.REQUEST, messageType, payload);
        dispatchEvent(event);
    }

    private function onSocketClose(event:Event) : void
    {
        trace("cucumber socket closed");
        destroy();
        dispatchEvent(new CucumberRequestEvent(CucumberRequestEvent.CONNECTION_CLOSED));
    }

}
}
