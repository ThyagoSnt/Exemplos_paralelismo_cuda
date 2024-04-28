#include <iostream>
#include <cuda_runtime.h>
#include <chrono>

// Função cuda que realiza o produto de vetores na gpu:
__global__ void multiply(int *a, int *b, int *c, int n) {
    int index = threadIdx.x + blockIdx.x * blockDim.x;
    if (index < n) {
        c[index] = a[index] * b[index];
        if(n<=10)
            printf("Thread %d executando, multiplicando %d * %d = %d\n", index, a[index], b[index], c[index]);
    }
}

// Função equivalente na cpu:
void mult_cpu(int *a, int *b, int *c, int n) {
    for (int i = 0; i < n; ++i) {
        c[i] = a[i] * b[i];
    }
}

int main() {
    // Variável que guarda as dimensões do vetor
    int n;

    std::cout << "Digite o tamanho desejado para os vetores: " << std::endl;
    std::cin >> n;

    // Declaração dos vetores cpu e gpu
    int *a, *b, *c;
    int *d_a, *d_b, *d_c;

    // Alocação de memória no dispositivo (GPU)
    cudaMalloc(&d_a, n * sizeof(int));
    cudaMalloc(&d_b, n * sizeof(int));
    cudaMalloc(&d_c, n * sizeof(int));

    // Alocação de memória na CPU
    a = new int[n];
    b = new int[n];
    c = new int[n];

    // Inicialização dos vetores a e b
    for (int i = 0; i < n; i++) {
        a[i] = i;
        b[i] = i;
    }

    if(n<=10){
        // Imprimir os vetores originais
        std::cout << "Vetor a: [";
        for (int i = 0; i < n; i++) {
            if(i<n-1)
                std::cout << a[i] << ", ";
            else
                std::cout << a[i];
        }
        std::cout << "]" << std::endl;

        std::cout << "Vetor b: [";
        for (int i = 0; i < n; i++) {
            if(i<n-1)
                std::cout << b[i] << ", ";
            else
                std::cout << b[i];
        }
        std::cout << "]" << std::endl;
    }

    // Copiar dados da CPU para a GPU
    cudaMemcpy(d_a, a, n * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, b, n * sizeof(int), cudaMemcpyHostToDevice);

    // Configurar a execução do kernel
    int blockSize = 1;
    int numBlocks = (n + blockSize - 1) / blockSize;

    // Captura o tempo atual antes da execução
    auto start = std::chrono::high_resolution_clock::now();

    // Chamar o kernel
    std::cout << "Chamando o kernel com " << numBlocks << " blocos e " << blockSize << " threads por bloco\n";
    multiply<<<numBlocks, blockSize>>>(d_a, d_b, d_c, n);

    // Copiar o resultado de volta para a CPU
    cudaMemcpy(c, d_c, n * sizeof(int), cudaMemcpyDeviceToHost);

    // Captura o tempo após a execução
    auto end = std::chrono::high_resolution_clock::now();

    // Calcula a duração, ou seja, o tempo decorrido
    std::chrono::duration<double> elapsed = end - start;

    // Converte a duração para segundos e imprime
    std::cout << "Tempo decorrido pelo processamento feito em cuda: " << elapsed.count() << " segundos" << std::endl;

    if(n<=10){
        // Imprimir o vetor resultado
        std::cout << "Vetor resultado: [";
        for (int i = 0; i < n; i++) {
            if(i<n-1)
                std::cout << c[i] << ", ";
            else
                std::cout << c[i];
        }
        std::cout << "]" << std::endl;
    }

    // Captura o tempo atual antes da execução
    auto start_cpu = std::chrono::high_resolution_clock::now();

    // Chamar a função de soma em CPU
    mult_cpu(a, b, c, n);

    // Captura o tempo após a execução
    auto end_cpu = std::chrono::high_resolution_clock::now();

    // Calcula a duração, ou seja, o tempo decorrido
    std::chrono::duration<double> elapsed_cpu = end_cpu - start_cpu;

    // Converte a duração para segundos e imprime
    std::cout << "Tempo decorrido pelo processamento feito em CPU: " << elapsed_cpu.count() << " segundos" << std::endl;

    // Liberar memória alocada
    delete[] a;
    delete[] b;
    delete[] c;
    cudaFree(d_a);
    cudaFree(d_b);
    cudaFree(d_c);

    return 0;
}
