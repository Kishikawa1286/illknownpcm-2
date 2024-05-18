using Pkg

function main()
    Pkg.add(
        Pkg.PackageSpec[
            Pkg.PackageSpec(name="Distributions"),
            Pkg.PackageSpec(name="HiGHS", version="1.9.0"),
            Pkg.PackageSpec(name="IntervalArithmetic", version="0.22.11"),
            Pkg.PackageSpec(name="JuMP"),
            Pkg.PackageSpec(name="LaTeXStrings"),
            Pkg.PackageSpec(name="Latexify"),
            Pkg.PackageSpec(name="Plots"),
            Pkg.PackageSpec(name="PyPlot"),
            Pkg.PackageSpec(name="StatsPlots"),
            Pkg.PackageSpec(name="Weave"),
            Pkg.PackageSpec(name="Ipopt", version="1.6.2")
        ]
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
