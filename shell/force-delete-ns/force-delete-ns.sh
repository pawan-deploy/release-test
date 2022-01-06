kubectl get ns

echo -e "\n"

read -p "Please enter namespace name: " ns

echo "Creating Json"

kubectl get ns $ns -o json > tmp.json

echo "Deleting finalizer value"

numbers=$(sed -n '/finalizers/=' tmp.json )

read -ra ln <<< "$numbers"

ln1=$(expr $ln + 1)
ln2=$(expr $ln + 2)

sed -i "s/\"finalizers\":.*/\"finalizers\": []/" tmp.json

sed -i "$ln1","$ln2"d tmp.json

echo "Deleting namespace $ns"

curl -sk -H "Content-Type: application/json" -X PUT --data-binary @tmp.json http://127.0.0.1:8001/api/v1/namespaces/$ns/finalize -o /dev/null

echo "Namespace $ns deleted"

rm -f tmp.json
