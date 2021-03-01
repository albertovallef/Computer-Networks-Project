module RoutingTableP{
    provides interface RoutingTable;

    uses interface Timer<TMilli> as RoutingTimer;
    uses interface SimpleSend as RSender;
    uses interface Receive as InternalReceive;
    uses interface NeighborDiscovery;

}
implementation{  

    //Periodic timer for updating the routing table

    //create struct(or header file) to store DVR information

    //RIP implementation (route advertising and merging routes)

    //Split Horizon implementation 

    //Poison Reverse technique implementation

    //Print Routing Table function

    /*
    Outputs:
    DEBUG(1): Routing Packet -src: 3, dest: 10, seq: 0, next hop: 2, cost: 26
    DEBUG (3): Routing Table:
    DEBUG (3): Dest  Hop  Count
    DEBUG (3): 6  6  1
    */

} 