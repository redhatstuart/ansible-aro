LOCATION=eastus
VNET="10.151.0.0"
CLUSTER="mycluster"
RESOURCE_GROUP="$CLUSTER-$LOCATION"

SUBID="f64d4ee8-be94-457d-ba26-3fa6b6506cef"
BUILDIN_SP_OBJID="50c17c64-bc11-4fdd-a339-0ecd396bf911" #don't touch it, hard coded
USER_PROVIDED_SP_OBJID="66ed1c46-8bea-4b9a-a58b-88b78e60f958" 
VNET_NAME="$CLUSTER-vnet"
VNET_OCTET1="$(echo $VNET | cut -f1 -d.)"
VNET_OCTET2="$(echo $VNET | cut -f2 -d.)"


echo -n "Creating Resource Group..."
az group create -g $RESOURCE_GROUP -l $LOCATION > /dev/null
echo "done"

echo -n "Creating Virtual Network..."
az network vnet create -g $RESOURCE_GROUP -n $VNET_NAME --address-prefixes $VNET/16 > /dev/null
echo "done"


echo -n "Creating Master Subnet..."
az network vnet subnet  create -g "$RESOURCE_GROUP" --vnet-name $VNET_NAME -n "$CLUSTER-master" --address-prefixes "$VNET_OCTET1.$VNET_OCTET2.$(shuf -i 0-254 -n 1).0/24" --service-endpoints Microsoft.ContainerRegistry > /dev/null
echo "done"
echo -n "Creating Worker Subnet..."
az network vnet subnet  create -g "$RESOURCE_GROUP" --vnet-name $VNET_NAME -n "$CLUSTER-worker" --address-prefixes "$VNET_OCTET1.$VNET_OCTET2.$(shuf -i 0-254 -n 1).0/24" --service-endpoints Microsoft.ContainerRegistry > /dev/null
echo "done"

echo -n "Disabling PrivateLinkServiceNetworkPolicies in Master subnet..."
az network vnet subnet update -g "$RESOURCE_GROUP" --vnet-name $VNET_NAME -n "$CLUSTER-master" --disable-private-link-service-network-policies true > /dev/null
echo "done"


echo -n "Assigning  VNET Contributor role to service principals..."
az role assignment create --role "Contributor" --assignee-object-id $BUILDIN_SP_OBJID --assignee-principal-type ServicePrincipal \
--scope /subscriptions/$SUBID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/virtualNetworks/$VNET_NAME  > /dev/null
az role assignment create --role "Contributor" --assignee-object-id $USER_PROVIDED_SP_OBJID --assignee-principal-type ServicePrincipal \
--scope /subscriptions/$SUBID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/virtualNetworks/$VNET_NAME > /dev/null 
echo "done"

echo -e "\nCopy Paste the followings to vars.yml\n"

echo "cluster_name: $CLUSTER"
echo "resource_group: $RESOURCE_GROUP"
echo "cluster_resource_group: /subscriptions/$SUBID/resourceGroups/$RESOURCE_GROUP-cluster"
echo "vent_id: /subscriptions/$SUBID/resourceGroups/$RESOURCE_GROUP/Microsoft.Network/virtualNetworks/$VNET_NAME"
echo "worker_subnet_id: /subscriptions/$SUBID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/$CLUSTER-worker"
echo "master_subnet_id: /subscriptions/$SUBID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/$CLUSTER-master"

