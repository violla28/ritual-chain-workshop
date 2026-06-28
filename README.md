# Privacy-Preserving AI Bounty Judge

## Alur Kerja (Lifecycle)

1. Membuat Bounty  
   Admin memanggil createBounty(bountyId, submissionDeadline, revealDeadline)

2. Fase Submission  
   Peserta submit commitment = keccak256(answer, salt, msg.sender, bountyId)

3. Fase Reveal  
   Peserta reveal jawaban, contract cek hash-nya

4. Fase Judging  
   Owner panggil judgeAll setelah reveal deadline

5. Finalisasi  
   Owner panggil finalizeWinner(bountyId, winnerIndex)
