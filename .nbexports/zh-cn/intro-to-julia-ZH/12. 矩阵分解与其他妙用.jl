
# ------------------------------------------------------------------------------------------
# # 矩阵分解与其他妙用
# 该教程由Andreas Noack所做的工作改编而成
#
# ## 大纲
#  - 矩阵分解
#  - 特殊矩阵
#  - 一般化线性代数
# ------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------
# 正式开始之前，让我们先来建立一个线性系统，并利用`LinearAlgebra`库来进行矩阵分解或处理特殊矩阵。
# ------------------------------------------------------------------------------------------

using LinearAlgebra
A = rand(3, 3)
x = fill(1, (3,))
b = A * x

# ------------------------------------------------------------------------------------------
# ## 矩阵分解
#
# #### LU分解
# 在Julia中，我们可以使用`lufact`进行LU分解：
# ```julia
# PA = LU
# ```
# 其中`P`是置换矩阵，`L`是对角全为1的下三角矩阵（单位下三角矩阵），`U`是上三角矩阵。
#
# Julia可以计算LU分解，并定义一个复合分解数据类型用以储存分解后的结果。
# ------------------------------------------------------------------------------------------

Alu = lu(A)

typeof(Alu)

# ------------------------------------------------------------------------------------------
# 可以通过这个类的特殊属性来调取分解出来的矩阵：
# ------------------------------------------------------------------------------------------

Alu.P

Alu.L

Alu.U

# ------------------------------------------------------------------------------------------
# Julia可以对储存分解结果的对象派发方法。
#
# 比如，在解算当前的线性系统时，我们既可以使用原本的矩阵，也可以使用分解运算所生成的对象：
# ------------------------------------------------------------------------------------------

A\b

Alu\b

# ------------------------------------------------------------------------------------------
# 相似地，要计算矩阵`A`的行列式，既可以使用原本的矩阵，也可以使用分解运算所生成的对象：
# ------------------------------------------------------------------------------------------

det(A) ≈ det(Alu)

# ------------------------------------------------------------------------------------------
# #### QR分解
#
# 在Julia中，可以使用`qrfact`来计算QR分解：
# ```
# A=QR
# ```
#
# 其中`Q`是正交阵/酉矩阵，`R`是上三角矩阵。
# ------------------------------------------------------------------------------------------

Aqr = qr(A)

# ------------------------------------------------------------------------------------------
# 与LU分解类似，矩阵`Q`和`R`可以通过以下语句从QR分解对象中调取：
# ------------------------------------------------------------------------------------------

Aqr.Q

Aqr.R

# ------------------------------------------------------------------------------------------
# #### 特征分解
# ------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------
# 特征分解、奇异值分解（SVD）、Hessenberg分解、Schur分解的结果都是以`Factorization`类型来储存的。
#
# 以下语句可用于计算特征值：
# ------------------------------------------------------------------------------------------

Asym = A + A'
AsymEig = eigen(Asym)

# ------------------------------------------------------------------------------------------
# 通过特殊索引，可以从Eigen类型中提取计算得到的特征值和特征向量：
# ------------------------------------------------------------------------------------------

AsymEig.values

AsymEig.vectors

# ------------------------------------------------------------------------------------------
# 再一次地，当分解结果被储存为特定的类型时，我们可以对它使用派发方法，也可以编写一些具有针对性的方法以充分利用矩阵分解的性质。例如，$A^{-1}=(V\Lambda
# V^{-1})^{-1}=V\Lambda^{-1}V^{-1}$。
# ------------------------------------------------------------------------------------------

inv(AsymEig)*Asym

# ------------------------------------------------------------------------------------------
# ## 特殊矩阵结构
# 矩阵结构在线性代数中有着尤为重要的作用。让我们通过一个大型线性系统来看看它到底有*多重要*吧：
# ------------------------------------------------------------------------------------------

n = 1000
A = randn(n,n);

# ------------------------------------------------------------------------------------------
# 通常，Julia可以自动推断出特殊矩阵结构：
# ------------------------------------------------------------------------------------------

Asym = A + A'
issymmetric(Asym)

# ------------------------------------------------------------------------------------------
# 但有时浮点误差会阻碍这一功能：
# ------------------------------------------------------------------------------------------

Asym_noisy = copy(Asym)
Asym_noisy[1,2] += 5eps()

issymmetric(Asym_noisy)

# ------------------------------------------------------------------------------------------
# 幸运的是，我们可以使用`Diagonal`（对角）、`Triangular`（三角）、`Symmetric`（对称）、`Hermitian`（厄米/自共轭矩阵）、`Tridiago
# nal`（三对角）、`SymTridiagonal`（对称三对角）等函数显式地定义特殊矩阵。
# ------------------------------------------------------------------------------------------

Asym_explicit = Symmetric(Asym_noisy);

# ------------------------------------------------------------------------------------------
# 现在，我们来比较Julia在计算`Asym`、`Asym_noisy`和`Asym_explicit`的特征值时各自需要多长时间：
# ------------------------------------------------------------------------------------------

@time eigvals(Asym);

@time eigvals(Asym_noisy);

@time eigvals(Asym_explicit);

# ------------------------------------------------------------------------------------------
# 在这个示例中，对`Asym_noisy`使用`Symmetric()`使得我们的运算效率提高了`5倍` :)
# ------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------
# #### 一个“大”问题
# 用`Tridiagonal`和`SymTridiagonal`类型储存三对角矩阵让我们得以处理有可能非常庞大的三对角问题。对于下面的示例问题而言，如果矩阵被储存为一个（稠密的）`M
# atrix`类型，那么一台笔记本电脑的配置将会不足以支持该问题的解算。
# ------------------------------------------------------------------------------------------

n = 1_000_000;
A = SymTridiagonal(randn(n), randn(n-1));
@time eigmax(A)

# ------------------------------------------------------------------------------------------
# ## 一般化线性代数
# 要在语言中添加对数值化的线性代数的支持，常规的手段是包装BLAS和LAPACK中的子程序。对于含有`Float32`、`Float64`、`Complex{Float32}`或`C
# omplex{Float64}`等类型的元素的矩阵，这正是Julia的处理方式。
#
# 然而，Julia也支持一般化的线性代数。运用这一特性的其中一个例子便是处理有理数矩阵和向量。
# ------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------
# #### 有理数
# Julia内嵌有对有理数的支持。使用双斜杠以构建一个有理数：
# ------------------------------------------------------------------------------------------

1//2

# ------------------------------------------------------------------------------------------
# #### 示例：有理数线性方程组
# 下面的例子将会演示如何在不将矩阵元素转化为浮点类型的前提下求解一个含有有理数的线性方程组。在处理有理数时，数值溢出很容易成为一个问题，因此我们使用`BigInt`类型：
# ------------------------------------------------------------------------------------------

Arational = Matrix{Rational{BigInt}}(rand(1:10, 3, 3))/10

x = fill(1, 3)
b = Arational*x

Arational\b

lu(Arational)

# ------------------------------------------------------------------------------------------
# ### 练习
#
# #### 11.1
# 求解矩阵A的特征值
#
# ```
# A =
# [
#  140   97   74  168  131
#   97  106   89  131   36
#   74   89  152  144   71
#  168  131  144   54  142
#  131   36   71  142   36
# ]
# ```
# 并将它赋给变量`A_eigv`。
# ------------------------------------------------------------------------------------------

using LinearAlgebra



@assert A_eigv ==  [-128.49322764802145, -55.887784553056875, 42.7521672793189, 87.16111477514521, 542.4677301466143]

# ------------------------------------------------------------------------------------------
# #### 11.2
# 由`A`的特征值构建一个`Diagonal`（对角）矩阵。
# ------------------------------------------------------------------------------------------



@assert A_diag ==  [-128.493    0.0      0.0      0.0       0.0;
    0.0    -55.8878   0.0      0.0       0.0;
    0.0      0.0     42.7522   0.0       0.0;
    0.0      0.0      0.0     87.1611    0.0;
    0.0 0.0      0.0      0.0     542.468]

# ------------------------------------------------------------------------------------------
# #### 11.3
# 由`A`构建一个`LowerTriangular`（下三角）矩阵，并将其储存为`A_lowertri`。
# ------------------------------------------------------------------------------------------



@assert A_lowertri ==  [140    0    0    0   0;
  97  106    0    0   0;
  74   89  152    0   0;
 168  131  144   54   0;
 131   36   71  142  36]

# ------------------------------------------------------------------------------------------
# ### 反馈与评价（英文）：
# https://tinyurl.com/introJuliaFeedback
# ------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------
# 完成练习后请点击顶部的`Validate`按钮。
# ------------------------------------------------------------------------------------------
