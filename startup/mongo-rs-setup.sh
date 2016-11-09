#!/bin/bash
echo "Running mongo-rs-setup.sh"

#set default rs name
if test -z $RS_NAME
    then RS_NAME=rs
fi

#check mongo hosts
if test -z $MONGODB_PRIMARY
    then echo "mongo primary host don't set"
    kill 0
fi
if test -z $MONGODB_SECONDARY
    then echo "mongo secondary host don't set"
    kill 0
fi
if test -z $MONGODB_ARBITER
    then echo "mongo arbiter host don't set"
    kill 0
fi
#set default ports
if test -z $MONGODB_PRIMARY_PORT
    then MONGODB_PRIMARY_PORT=27017
fi
if test -z $MONGODB_SECONDARY_PORT
    then MONGODB_SECONDARY_PORT=27017
fi
if test -z $MONGODB_ARBITER_PORT
    then MONGODB_ARBITER_PORT=27017
fi

MONGODB_PRIMARY_IP=`ping -c 1 $MONGODB_PRIMARY | head -1  | cut -d "(" -f 2 | cut -d ")" -f 1`
MONGODB_SECONDARY_IP=`ping -c 1 $MONGODB_SECONDARY | head -1  | cut -d "(" -f 2 | cut -d ")" -f 1`
MONGODB_ARBITER_IP=`ping -c 1 $MONGODB_ARBITER | head -1  | cut -d "(" -f 2 | cut -d ")" -f 1`

echo "mongo primary ip:$MONGODB_PRIMARY_IP"
echo "mongo secondary ip:$MONGODB_SECONDARY_IP"
echo "mongo arbiter ip:$MONGODB_ARBITER_IP"

echo "Waiting for startup on mongo $MONGODB_PRIMARY.."
until curl http://$MONGODB_PRIMARY:$MONGODB_PRIMARY_PORT/serverStatus\?text\=1 2>&1 | grep uptime | head -1; do
  printf '.'
  sleep 1
done

echo "Waiting for startup on mongo $MONGODB_SECONDARY.."
until curl http://$MONGODB_SECONDARY:$MONGODB_SECONDARY_PORT/serverStatus\?text\=1 2>&1 | grep uptime | head -1; do
  printf '.'
  sleep 1
done

echo "Waiting for startup on mongo $MONGODB_ARBITER.."
until curl http://$MONGODB_ARBITER:$MONGODB_ARBITER_PORT/serverStatus\?text\=1 2>&1 | grep uptime | head -1; do
  printf '.'
  sleep 1
done

echo "Replicas started..."
mongo --host $MONGODB_PRIMARY <<EOF

   var cfg = {
        "_id": "$RS_NAME",
        "version": 1,
        "members": [
            {
                "_id": 0,
                "host": "$MONGODB_PRIMARY:$MONGODB_PRIMARY_PORT",
                "priority": 2
            },
            {
                "_id": 1,
                "host": "$MONGODB_SECONDARY:$MONGODB_SECONDARY_PORT",
                "priority": 1
            },
            {
                "_id": 2,
                "host": "$MONGODB_ARBITER:$MONGODB_ARBITER_PORT",
                "priority": 1,
                "arbiterOnly" : true
            }
        ]
    };
    try{
        var config = rs.config();
        rs.reconfig(cfg, { force: true });
    }catch(err){
        rs.initiate(cfg);
    }
EOF