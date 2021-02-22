//header from Node (using the same implementation ping to ping)
#include <Timer.h>
#include "../../includes/command.h"
#include "../../includes/packet.h"
#include "../../includes/channels.h"
#include "../../includes/protocol.h"

#define NEIGHBORHOOD_SIZE 4; //how many nodes do we need?

module NeighborDiscoveryP{
    provides interface NeighborDiscovery;

    uses interface Timer<TMilli> as PeriodicTimer;
    uses interface SimpleSend as NSender;
    uses interface Receive as NReceiver;
    uses interface Random as RandomTimer;
    uses interface List<pack> as NList;

}
implementation{

    pack sendPackage;
    uint16_t timer2;
    uint16_t timer1;
    uint32_t seqNumber;

    // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
   void updateNeighbors(); //Updates active and inactive neighbors
   void discoverNeighbors(); 

   command void NeighborDiscovery.start(){ //command called when booting
    timer1 = (1000 + (uint16_t)((call RandomTimer.rand16())%1000)); 
    timer2 = (1000 + (uint16_t)((call RandomTimer.rand16())%2000));
    dbg(NEIGHBOR_CHANNEL, "Timer: %d to %d\n", timer1, timer2); //created a peridoic timer from period t1 to t2
    call PeriodicTimer.startPeriodicAt(timer1, timer2); //the first timer will fire first
   } 

   event void PeriodicTimer.fired() //fired means that TOS_NODE_ID is sending signal in all directions, the smaller timer fires first
   {
      dbg(NEIGHBOR_CHANNEL, "Node %d fires!\n", TOS_NODE_ID);
      discoverNeighbors();

   }     

   void discoverNeighbors(){
         dbg(NEIGHBOR_CHANNEL, "%d is searching for neighbors...\n", TOS_NODE_ID);
         makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 4, PROTOCOL_PING, seqNumber+1, "are we neighbors?", PACKET_MAX_PAYLOAD_SIZE);
         dbg(NEIGHBOR_CHANNEL, "%d is sending packet(broadcasting)...\n", TOS_NODE_ID);
         call NSender.send(sendPackage, AM_BROADCAST_ADDR); //sending package to everyone near node(the one that fired)

                                                            //we use protocol ping reply for neighbor discovery
      }

   event message_t* NReceiver.receive(message_t* msg, void* payload, uint8_t len){
      
      if(len == sizeof(pack)){
         pack* myMsg=(pack*) payload;
         dbg(NEIGHBOR_CHANNEL, "Sequence number: %d\n", myMsg->seq);
         dbg(NEIGHBOR_CHANNEL, "Node %d recieved packet from node %d\n", TOS_NODE_ID, myMsg->src);
         if(myMsg->TTL != 0){ //need to create function && checkPacketList(myMsg) == FALSE
            if(myMsg->protocol == PROTOCOL_PING){
               dbg(NEIGHBOR_CHANNEL, "Node %d recieved packet with protocol ping, sending reply back to node %d\n", TOS_NODE_ID, myMsg->src); 
               makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, myMsg->TTL-1, PROTOCOL_PINGREPLY, seqNumber, "We are neighbors!", PACKET_MAX_PAYLOAD_SIZE);
               call NSender.send(sendPackage, myMsg->src); //sending reply to the node that broadcasted
            }
            else if(myMsg->protocol == PROTOCOL_PINGREPLY){ //if node that broadcasted recieves reply
               dbg(NEIGHBOR_CHANNEL, "Node %d recieved reply back from node %d!\n", TOS_NODE_ID, myMsg->src);
               dbg(NEIGHBOR_CHANNEL, "Packet payload: %s\n", myMsg->payload);
               myMsg->dest = TOS_NODE_ID;
               call NList.pushback(*myMsg);
               // call NeighborDiscovery.print();
               //At some point we implement flooding to continue broadcasting to other close nodes
            }
         }
      // call FSender.send(sendPack, AM_BROADCAST_ADDR); //sender to start flooding
      return msg;
      }
   }   
                                        
   command void NeighborDiscovery.print(){ //TOS_NODE_ID is the node fired
      uint16_t i = 0;
      uint16_t listSize = call NList.size();
      pack neighbor; 

      dbg(GENERAL_CHANNEL, "Printing neighbors of %d: \n", TOS_NODE_ID);
      if (listSize == 0){
         dbg(NEIGHBOR_CHANNEL, "No neighbors \n", TOS_NODE_ID)
      }
      else{
      for(i=0; i < listSize; i++){
         neighbor = call NList.get(i);
         if(TOS_NODE_ID == neighbor.dest){
         dbg(NEIGHBOR_CHANNEL, "Node %d is neighbor with %d with sequence number: %d \n", TOS_NODE_ID, neighbor.src, neighbor.seq);
         }
      }
      }
      return;
   }

   void updateNList(uint16_t src){
      // uint16_t i;
      // pack newNeighbor;
      // for(i = 0; i<NList.size(); i++){
      //    newNeighbor = call NList.get(i);
      //    if(newNeighbor.TTL = TIMEOUT);
      //       return;
      //    newNeighbor.src = src;
      //    newNeighbor.TTL = TIMEOUT;
      //    seqCounter++;
      // }
   }

   void makePack(pack* Packet, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length)
   {
       Packet->src = src;
      Packet->dest = dest;
      Packet->TTL = TTL;
      Packet->seq = seq;
      Packet->protocol = protocol;
      memcpy(Packet->payload, payload, length);
   }

}