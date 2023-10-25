function universallyUniqueIdentifier = CreateUUID

temp = java.util.UUID.randomUUID;
% universallyUniqueIdentifier = temp.toString;
universallyUniqueIdentifier = string(temp);
end