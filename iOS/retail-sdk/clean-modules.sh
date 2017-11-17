mkdir -p tmp_node
echo "Moving real code"
mv node_modules/miura-emv tmp_node
echo "Removing the rest"
rm -rf node_modules/*
rm -rf tmp_node/miura_emv/node_modules
mv tmp_node/miura-emv node_modules
rmdir tmp_node
echo "Done"
