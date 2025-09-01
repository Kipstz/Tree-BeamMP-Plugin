-- Test du nouveau système de chargement de bibliothèques
dofile("main.lua")

print("\n^e=== Test du système de bibliothèques Tree ===^7")

print("^2Structure actuelle:^7")
print("  ^3- Tree-BeamMP-Plugin/ (framework - pas de lib/)^7")  
print("  ^3- test/lib/ (dossier lib du plugin test)^7")

if TestPlugin and TestPlugin.Utils then
    print("\n^6Test d'appel de Tree.LoadLib() depuis le plugin test:^7")
    local result = TestPlugin.Utils.testLibLoading()
    
    print("\n^2Résultat attendu:^7")
    print("  ^3- Tree détecte que l'appel vient du plugin 'test'^7")
    print("  ^3- Tree cherche dans test/lib/json.dll (ou .so)^7") 
    print("  ^3- Si pas trouvé, essaie require('json')^7")
    print("  ^3- Affiche un message d'erreur si échec complet^7")
else
    print("^1Erreur: Plugin test non chargé !^7")
end

print("\n^2=== Test terminé ===^7")