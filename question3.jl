# Le package Plots va nous permettre de dessiner
# mais il faut auparavant avoir taper: import Pkg; Pkg.add("Plots")

ENV["GKSwstype"] = "nul"  # redirige les sorties de Plots vers les fichiers et non à l'écran
using Plots
using JuMP
using CPLEX
using Random

# Fonction qui lit un fichier de données et renvoie le nombre de données et la liste des données
# Retourne: n: nombre de villes
# Remplit les tableaux
#    tabX, tabY: coordonnées des villes
#    f: poids des villes

function Lit_fichier_UFLP(nom_fichier, tabX, tabY, f)

  n=0
  
  open(nom_fichier) do fic

        for (i,line) in enumerate(eachline(fic)) 
              lg = split(line," ")      # découpe la ligne suivant les espaces et crée un tableau 
              if (i<=1) 
                  n= parse(Int,lg[1])
              end
              if (i>=2) && (i<=n+1) 
                 push!(tabX,parse(Float64,lg[3]))
                 push!(tabY,parse(Float64,lg[4]))	
                 push!(f,parse(Float64,lg[5]))               
              end              
        end    
  end
  return n
end

function Lit_coordonnees_ville(nom_fichier, coordVillesX, coordVillesY)
  
  open(nom_fichier) do fic

        for (i,line) in enumerate(eachline(fic)) 
              lg = split(line," ")      # découpe la ligne suivant les espaces et crée un tableau 
              push!(coordVillesX,parse(Float16,lg[5]))
              push!(coordVillesY,parse(Float16,lg[6]))	
        end    
  end
end

# Fonction Dessine instance
function Dessine_UFLP(nom_fichier)

    n=0
    tabX=Float64[]
    tabY=Float64[]
    f= Float64[]
    
    println("Lecture du fichier: ", nom_fichier)

    n= Lit_fichier_UFLP(nom_fichier, tabX, tabY, f)

    println("Le fichier contient ",n, " villes")
  
    nom_fichier_en_deux_morceaux = split(nom_fichier,".") # découpe le nom du fichie d'entrée sans l'extension
    nom_fichier_avec_pdf_a_la_fin= nom_fichier_en_deux_morceaux[1]*".pdf"

    println("Création du fichier pdf de l'instance: ", nom_fichier_avec_pdf_a_la_fin)

    Plots.plot(tabX,tabY,seriestype = :scatter)
    Plots.savefig(nom_fichier_avec_pdf_a_la_fin)  # Ecrit la courbe créée à la ligne précédente dans un fichier .pdf
    
end

# Fonction pour calculer la distance euclidienne entre deux points
function dist(x1, y1, x2, y2)
    return sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

# Fonction Dessine solution
function Dessine_UFLP(nom_fichier, n, tabX, tabY, S)

    X=Float64[]
    Y=Float64[]	
    
    nom_fichier_en_deux_morceaux = split(nom_fichier,".") # découpe le nom du fichie d'entrée sans l'extension
    nom_fichier_avec_pdf_a_la_fin= nom_fichier_en_deux_morceaux[1]*"_sol.pdf"

    println("Création du fichier pdf de la solution: ", nom_fichier_avec_pdf_a_la_fin)

    Plots.plot(tabX,tabY,seriestype = :scatter, legend = false)
    
    for i=1:n
       min=10e10
       minj=0
       for j=1:n
          if ( (S[j]==1) && (min>dist(tabX[i],tabY[i],tabX[j],tabY[j])) )
              min=dist(tabX[i],tabY[i],tabX[j],tabY[j])                          
              minj=j             
          end
       end
       if (i!=minj)
          empty!(X)
          empty!(Y)			
          push!(X,tabX[i])
          push!(X,tabX[minj])	
          push!(Y,tabY[i])
          push!(Y,tabY[minj])	          
          Plots.plot!(X,Y, legend = false)
       end
    end

    Plots.savefig(nom_fichier_avec_pdf_a_la_fin)  # Ecrit la courbe créée à la ligne précédente dans un fichier .pdf
end

function resoudre_UFLP(n, tabX, tabY, p)

    # Créer le modèle
    model = Model(CPLEX.Optimizer)

    # Définir les variables
    @variable(model, x[1:n, 1:n], Bin)
    @variable(model, y[1:n], Bin)
    @variable(model, z >= 0)

    # Définir les contraintes
    @constraint(model, sum(y[j] for j in 1:n) <= p)  # Contrainte (1)
    @constraint(model, [i=1:n], sum(x[i, j] for j in 1:n) == 1)  # Contrainte (2)
    @constraint(model, [i=1:n, j=1:n], x[i, j] <= y[j])  # Contrainte (3)
    @constraint(model, [i=1:n], sum(dist(tabX[i], tabY[i], tabX[j], tabY[j]) * x[i, j] for j in 1:n) <= z) # Contrainte (4)

    # Définir l'objectif
    @objective(model, Min, z)

    # Résoudre le modèle
    optimize!(model)

    # Afficher les résultats
    println("Distance maximale minimisée (z): ", value(z))

    return value(z), value.(y), value.(x)
end

# Création des tableaux nécessaires
tabX = Float64[]
tabY = Float64[]
f = Float64[]

# Appel de la fonction Lit_fichier_UFLP
n = Lit_fichier_UFLP("inst_50000.flp", tabX, tabY, f)

# Affichage des résultats
println("Nombre de villes: ", n)
p = 10
z,S,x = resoudre_UFLP(n, tabX, tabY, p)
Dessine_UFLP("res", n, tabX, tabY, S)