// queryViews.ts
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

/**
 * Fetches all dashboard views and logs the results.
 * Busca todas as views do dashboard e imprime os resultados.
 */
async function main() {
  try {
    // Views que medem o impacto e status dos patrocínios
    const activeSponsoredOwners = await prisma.$queryRawUnsafe(`SELECT * FROM vw_active_sponsored_owners`);
    const allSponsoredOwners = await prisma.$queryRawUnsafe(`SELECT * FROM vw_all_sponsored_owners`);
    const storeImpact = await prisma.$queryRawUnsafe(`SELECT * FROM vw_store_impact`);
    const userImpact = await prisma.$queryRawUnsafe(`SELECT * FROM vw_user_impact`);
    const communityImpact = await prisma.$queryRawUnsafe(`SELECT * FROM vw_community_impact`);
    const totalImpactedUsers = await prisma.$queryRawUnsafe(`SELECT * FROM vw_total_impacted_users`);

    // Exibe os dados no console (pode substituir por retorno de API futuramente)
    console.log({
      activeSponsoredOwners,
      allSponsoredOwners,
      storeImpact,
      userImpact,
      communityImpact,
      totalImpactedUsers,
    });

  } catch (error) {
    console.error('Erro ao consultar as views:', error);
  } finally {
    await prisma.$disconnect();
  }
}
main();