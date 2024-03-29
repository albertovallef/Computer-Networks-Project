//header from Node (using the same implementation ping to ping)
#include <Timer.h>
#include "../../includes/command.h"
#include "../../includes/packet.h"
#include "../../includes/channels.h"
#include "../../includes/protocol.h"
#include "../../includes/route.h"

module NeighborDiscoveryP{
    provides interface NeighborDiscovery;

    uses interface Timer<TMilli> as PeriodicTimer;
    uses interface SimpleSend as NSender;
   //  uses interface SimpleSend as FSender;
   // uses interface Flooding;
    uses interface Receive as NReceiver;
    uses interface Random as RandomTimer;
    uses interface List<pack> as PacketList;
    uses interface List<uint16_t> as NeighborList;
    uses interface List<Route> as RouteTable;
    uses interface Hashmap<Route> as RoutingTable;

}
implementation{

    pack sendPackage;
    Route routingPacket;
    uint16_t timer2;
    uint16_t timer1;
    uint32_t seqNum = 0;

    // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
   void updatePacketList(pack *myMsg); //Updates active and inactive neighbors
   void discoverNeighbors();
   bool checkPackets(pack *myMsg, uint16_t dest);
   void addPacket(pack Pack);

   command void NeighborDiscovery.start()
   {  //command called when booting
      timer1 = (1000 + (uint16_t)((call RandomTimer.rand16())%1000)); 
      timer2 = (2000 + (uint16_t)((call RandomTimer.rand16())%2000));
      dbg(NEIGHBOR_CHANNEL, "Neighbor discovery timer: %d + %d\n", timer1, timer2); //created a peridoic timer from period t1 to t2
      call PeriodicTimer.startPeriodicAt(timer1, timer2); //the first timer will fire first
   } 

   event void PeriodicTimer.fired() //fired means that TOS_NODE_ID is sending signal in all directions, the smaller timer fires first
   {
      // dbg(NEIGHBOR_CHANNEL, "Node %d fires!\n", TOS_NODE_ID);
      discoverNeighbors();
   }     

   void discoverNeighbors(){
         seqNum++;
         // dbg(NEIGHBOR_CHANNEL, "%d is searching for neighbors: sending packet(broadcasting)...\n", TOS_NODE_ID);
         makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 4, PROTOCOL_PING, seqNum, "are we neighbors?", PACKET_MAX_PAYLOAD_SIZE);
         call NSender.send(sendPackage, AM_BROADCAST_ADDR); //sending package to everyone near node(the one that fired)
                                                            //we use protocol ping reply for neighbor discovery
      }

   event message_t* NReceiver.receive(message_t* msg, void* payload, uint8_t len){
      
      if(len == sizeof(pack))
      {
         pack* myMsg=(pack*) payload;
         uint16_t i = 0;
         uint16_t listSize = 0;
         uint16_t newNeighbor;
         bool inList = FALSE;
         // dbg(NEIGHBOR_CHANNEL, "Node %d recieved packet from node %d\n", TOS_NODE_ID, myMsg->src);
         
         if( myMsg->TTL != 0) //&&checkPackets(myMsg, TOS_NODE_ID) == FALSE
         { 
            if(myMsg->protocol == PROTOCOL_PING)
            {
               // dbg(NEIGHBOR_CHANNEL, "Node %d recieved packet with protocol Ping, sending reply back to node %d\n", TOS_NODE_ID, myMsg->src); 
               makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, myMsg->TTL-1, PROTOCOL_PINGREPLY, seqNum, "We are neighbors!", PACKET_MAX_PAYLOAD_SIZE);
               call NSender.send(sendPackage, myMsg->src); //sending reply to the node that broadcasted
               return msg;
            }
            
            else if(myMsg->protocol == PROTOCOL_PINGREPLY) //if node that broadcasted recieves reply
            {  
               // dbg(NEIGHBOR_CHANNEL, "Node %d recieved reply back from node %d!\n", TOS_NODE_ID, myMsg->src);
               // dbg(NEIGHBOR_CHANNEL, "Packet payload: %s\n", myMsg->payload);
               
               listSize = call NeighborList.size();
               for(i = 0; i< listSize; i++)
               {
                  newNeighbor = call NeighborList.get(i);
                  if(myMsg->src == newNeighbor)
                  {
                     // dbg(NEIGHBOR_CHANNEL, "Neighbor is already in list!\n");
                     inList = TRUE;
                  }
               }

               if(inList == FALSE)
               {
               // dbg(NEIGHBOR_CHANNEL, "Adding node %d to neighbor list...\n", myMsg->src);   
               call NeighborList.pushback(myMsg->src);
               // routingPacket.src = myMsg->src;
               routingPacket.dest = myMsg->src;
               routingPacket.seq = myMsg->seq;
               routingPacket.cost = 1;
               routingPacket.nextHop = myMsg->src;
               call RouteTable.pushback(routingPacket);
               call RoutingTable.remove(myMsg->src);
               call RoutingTable.insert(myMsg->src, routingPacket);
               }
               return msg;
               //At some point we implement flooding to continue broadcasting to other close nodes
            }  
         }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
      }
   } 

   bool checkPackets(pack *myMsg, uint16_t dest)
   {
      uint16_t i = 0;
      uint16_t listSize = call PacketList.size();
      pack neighbor; 
      for(i = 0; i<listSize; i++)
      {
         neighbor = call PacketList.get(i);
         // dbg(NEIGHBOR_CHANNEL, "src %d dest %d\n", neighbor.src, neighbor.dest);
         if(neighbor.dest == dest && myMsg->src == neighbor.src)
         {
            return TRUE;
         }
      }
      return FALSE;
   } 
   void addPacket(pack Packet)
   {
      call PacketList.pushback(Packet);
   }

   void updatePacketList(pack *myMsg)
   {
      uint16_t i;
      uint16_t listSize = call PacketList.size();
      pack newNeighbor;
      bool inPacketList;
      inPacketList = FALSE;

      for(i = 0; i< listSize; i++)
      {
         newNeighbor = call PacketList.get(i);
         if(myMsg->src == newNeighbor.src && myMsg->dest == newNeighbor.dest)
         {
            inPacketList = TRUE;
            return;
         }
      }

      if(inPacketList == FALSE)
      {
         makePack(&sendPackage, TOS_NODE_ID, myMsg->src, myMsg->TTL-1, PROTOCOL_PINGREPLY, seqNum, "We are neighbors!", PACKET_MAX_PAYLOAD_SIZE);
         addPacket(sendPackage);
      }
      return;
   }
                                        
   command void NeighborDiscovery.print()
   {  //TOS_NODE_ID is the node fired
      uint16_t i = 0;
      uint16_t listSize = call NeighborList.size();
      uint16_t neighbor; 

      dbg(GENERAL_CHANNEL, "Printing neighbors of %d: \n", TOS_NODE_ID);
      // dbg(GENERAL_CHANNEL, "List size: %d \n", listSize);

      if (listSize == 0)
      {
         dbg(NEIGHBOR_CHANNEL, "No neighbors \n");
      }
      else
      {
         for(i=0; i < listSize; i++)
         {
            neighbor = call NeighborList.get(i);
            dbg(NEIGHBOR_CHANNEL, "Node %d is neighbor with %d\n", TOS_NODE_ID, neighbor);
         }
      }
      return;
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