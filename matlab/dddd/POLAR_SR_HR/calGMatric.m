function G = calGMatric(n)
    F = [1 0;1 1];
    G = F;
    while(n>1)
        G = kron(F, G);
        n = n-1;
    end
end