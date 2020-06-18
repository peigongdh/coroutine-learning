'use strict';
 
const net = require('net');
const PORT = 12321;
const HOST = 'localhost';
 
class Client {
 constructor(port, address) {
  this.socket = new net.Socket();
  this.address = address || HOST;
  this.port = port || PORT;
  this.init();
 }
 
 init() {
  var client = this;
  client.socket.connect(client.port, client.address, () => {
   console.log(`Client connected to: ${client.address} :  ${client.port}`);
  });
 
  client.socket.on('close', () => {
   console.log('Client closed');
  });
 }
 
 sendMessage(message) {
  var client = this;
  return new Promise((resolve, reject) => {
 
   client.socket.write(message);
 
   client.socket.on('data', (data) => {
    resolve(data);
    if (data.toString().endsWith('exit')) {
     client.socket.destroy();
    }
   });
 
   client.socket.on('error', (err) => {
    reject(err);
   });
 
  });
 }
}
module.exports = Client;

const client = new Client();
client.sendMessage('A')
.then((data)=> { console.log(`Received: ${data}`);  return client.sendMessage('B');} )
.then((data)=> { console.log(`Received: ${data}`);  return client.sendMessage('C');} )
.then((data)=> { console.log(`Received: ${data}`);  return client.sendMessage('exit');} )
.catch((err) =>{ console.error(err); })